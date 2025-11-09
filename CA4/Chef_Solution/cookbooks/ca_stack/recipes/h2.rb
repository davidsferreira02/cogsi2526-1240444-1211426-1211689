#
# Cookbook:: ca_stack
# Recipe:: h2
#
# Installs and configures H2 Database server.
#

# --- Update apt repositories ---
apt_update 'update_packages' do
  action :update
end

# --- Apply PAM/user policy first ---
include_recipe 'ca_stack::pam_policy'

# --- Install required packages ---
%w(openjdk-17-jre-headless ufw curl unzip).each do |pkg|
  package pkg
end

directory '/opt/h2' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

directory '/data/h2' do
  owner 'vagrant'
  group 'vagrant'
  mode '0755'
  recursive true
  action :create
end

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

# --- Download H2 JAR ---
remote_file "/opt/h2/h2-#{node['ca']['h2_version']}.jar" do
  source "https://repo1.maven.org/maven2/com/h2database/h2/#{node['ca']['h2_version']}/h2-#{node['ca']['h2_version']}.jar"
  mode '0644'
end

# --- Initialize database (only once) ---
bash 'init_h2_db' do
  code <<~BASH
    echo "CREATE TABLE IF NOT EXISTS payroll_init (id INT PRIMARY KEY, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP());" > /tmp/init.sql
    /usr/bin/java -cp "/opt/h2/h2-#{node['ca']['h2_version']}.jar" org.h2.tools.RunScript \
      -url "jdbc:h2:/data/h2/payrolldb" -user sa -password password -script /tmp/init.sql
    rm -f /tmp/init.sql
    mv /data/h2 #{node['ca']['dev_dir']}/h2-db
    chown root:developers #{node['ca']['dev_dir']}/h2-db
    chmod 0770 #{node['ca']['dev_dir']}/h2-db
  BASH
  creates "#{node['ca']['dev_dir']}/h2-db"
end

# --- Create systemd service file ---
template '/etc/systemd/system/h2.service' do
  source 'h2.service.erb'
  mode '0644'
  variables(h2_version: node['ca']['h2_version'])
  notifies :run, 'execute[daemon-reload]', :immediately
end

execute 'daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

# --- Enable and start H2 service ---
service 'h2' do
  action node['ca']['start_db'] ? [:enable, :start] : [:disable, :stop]
end

# --- Configure firewall (UFW) ---
execute 'ufw_enable' do
  command 'ufw --force enable'
  not_if "ufw status | grep -q 'Status: active'"
end

execute 'ufw_allow_ssh' do
  command 'ufw allow OpenSSH'
  not_if "ufw status | grep -E '^OpenSSH.*ALLOW'"
end

execute 'ufw_allow_app' do
  command "ufw allow from #{node['ca']['app_ip']} to any port 9092 proto tcp"
  not_if "ufw status | grep -q '#{node['ca']['app_ip']}.*9092/tcp'"
end

# --- Health check: ensure H2 TCP port is accepting connections ---
ruby_block 'wait_for_h2_port' do
  block do
    require 'socket'
    require 'timeout'
    deadline = Time.now + 120
    last_error = nil
    loop do
      begin
        Timeout.timeout(3) do
          s = TCPSocket.new('127.0.0.1', 9092)
          s.close
          break
        end
      rescue => e
        last_error = e
        if Time.now > deadline
          raise "H2 port 9092 did not become available: #{last_error.class}: #{last_error.message}"
        end
        sleep 2
      end
    end
  end
  only_if { node['ca']['start_db'].to_s == 'true' }
end
