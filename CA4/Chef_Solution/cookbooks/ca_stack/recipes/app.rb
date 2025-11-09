#
# Cookbook:: ca_stack
# Recipe:: app
#
# Builds and deploys the Spring Boot application.
#

apt_update 'update_packages' do
  action :update
end

# Optional: install dmidecode to silence shard_seed warnings on Chef
package 'dmidecode' do
  action :install
end

include_recipe 'ca_stack::pam_policy'

# Ensure developers group exists
group 'developers' do
  action :create
end

# Create devuser and add to developers group
user 'devuser' do
  group 'developers'
  shell '/bin/bash'
  password '6684282bf0c558ae99560ccd9eea5c3ba9d36767132a11a8298bdc6fcb0d368d623fd1305f2c6ac2782a5356d425fc664661c3f9503e7b37c9c2401a05d8130c'
  action :create
end

# Create /opt/developers directory with restricted access
directory node['ca']['dev_dir'] do
  owner 'root'
  group 'developers'
  mode '0750'
  recursive true
  action :create
end

%w(openjdk-17-jdk maven gradle curl jq netcat-openbsd).each do |pkg|
  package pkg
end

# Update application.properties for DB connection
app_props = "#{node['ca']['app_project_dir']}/app/src/main/resources/application.properties"

ruby_block 'write application.properties' do
  block do
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(app_props))
    File.write(app_props, <<~CFG)
      spring.datasource.url=jdbc:h2:tcp://#{node['ca']['db_ip']}:9092//opt/developers/h2-db/payrolldb
      spring.datasource.driverClassName=org.h2.Driver
      spring.datasource.username=sa
      spring.datasource.password=password
      spring.jpa.hibernate.ddl-auto=update
    CFG
  end
end

bash 'build_spring_app' do
  cwd node['ca']['app_project_dir']
  code <<~BASH
    set -e
    # Dynamically set JAVA_HOME based on javac location (portable across arch)
    if command -v javac >/dev/null 2>&1; then
      export JAVA_HOME="$(dirname "$(readlink -f "$(which javac)")")/.."
    fi
    if [ -f ./gradlew ]; then
      chmod +x ./gradlew || true
      ./gradlew bootJar --no-daemon
    elif [ -f ./build.gradle ] || [ -f ./build.gradle.kts ]; then
      echo "Gradle wrapper não encontrado — a gerar wrapper e construir"
      gradle wrapper --no-daemon
      ./gradlew bootJar --no-daemon
    elif [ -f ./pom.xml ]; then
      echo "Projeto Maven detetado — a construir"
      mvn -q -DskipTests package
    else
      echo "Nenhum ficheiro de build encontrado em #{node['ca']['app_project_dir']}" >&2
      echo "Esperava 'gradlew', 'build.gradle(.kts)' ou 'pom.xml'." >&2
      exit 2
    fi
  BASH
  environment({
    'HOME' => '/home/vagrant'
  })
  only_if { node['ca']['build_app'].to_s == 'true' }
end

# Copy JAR to /opt/developers
bash 'copy_jar' do
  code <<~BASH
    set -e
    CANDIDATES=(
      "#{node['ca']['app_project_dir']}/app/build/libs/*.jar"
      "#{node['ca']['app_project_dir']}/build/libs/*.jar"
      "#{node['ca']['app_project_dir']}/app/target/*.jar"
      "#{node['ca']['app_project_dir']}/target/*.jar"
    )
    JAR=""
    for pattern in "${CANDIDATES[@]}"; do
      for f in $pattern; do
        if [ -f "$f" ]; then
          echo "Found candidate: $f"
          JAR="$f"
        fi
      done
      [ -n "$JAR" ] && break
    done
    if [ -z "$JAR" ]; then
      echo "No built jar found under known locations." >&2
      exit 3
    fi
    # Prefer non-plain JAR if possible
    # If the selected JAR is a *-plain.jar (Gradle produces a plain + bootable JAR),
    # prefer the non-plain (bootable) variant. Use '--' to stop grep option parsing
    # because the pattern starts with a dash.
    if echo "$JAR" | grep -q -- "-plain"; then
      ALT=$(ls -t ${JAR%-plain*.jar}*.jar 2>/dev/null | head -n1 || true)
      [ -n "$ALT" ] && JAR="$ALT"
    fi
    cp "$JAR" #{node['ca']['dev_dir']}/spring-app.jar
    chown root:developers #{node['ca']['dev_dir']}/spring-app.jar
    chmod 0640 #{node['ca']['dev_dir']}/spring-app.jar
  BASH
end

# Create systemd unit
template '/etc/systemd/system/ca4-app.service' do
  source 'ca4-app.service.erb'
  mode '0644'
  variables(app_port: node['ca']['app_port'])
  notifies :run, 'execute[daemon-reload]', :immediately
end

execute 'daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

service 'ca4-app' do
  action node['ca']['start_app'] ? [:enable, :start] : [:disable, :stop]
end

# --- Health checks: ensure app is listening and responding ---
execute 'wait_for_app_tcp_port' do
  command "bash -lc 'for i in {1..60}; do nc -z 127.0.0.1 #{node['ca']['app_port']} && exit 0; sleep 2; done; exit 1'"
  retries 0
  timeout 130
  only_if { node['ca']['start_app'].to_s == 'true' }
end

execute 'http_health_check_app_root' do
  command "curl --fail --silent --show-error http://localhost:#{node['ca']['app_port']}/ -o /dev/null"
  retries 10
  retry_delay 3
  only_if { node['ca']['start_app'].to_s == 'true' }
end
