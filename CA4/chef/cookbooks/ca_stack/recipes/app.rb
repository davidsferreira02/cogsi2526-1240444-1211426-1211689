apt_update 'update_packages' do
  action :update
end

include_recipe 'ca_stack::pam_policy'

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
  cwd node['ca']['app_project_dir']  # this should already be /workspace/CA2/Part2
  code './gradlew :app:bootJar'
  environment({ 'JAVA_HOME' => '/usr/lib/jvm/java-17-openjdk-amd64' })
  only_if { node['ca']['build_app'] }
end


# Copy JAR to /opt/developers
bash 'copy_jar' do
  code <<~BASH
    JAR=$(ls -t #{node['ca']['app_project_dir']}/app/build/libs/*.jar | grep -v plain | head -n1)
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
