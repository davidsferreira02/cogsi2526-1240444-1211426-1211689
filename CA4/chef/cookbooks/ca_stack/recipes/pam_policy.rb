#
# Cookbook:: ca_stack
# Recipe:: pam_policy
#
# Enforces PAM password hardening and creates system user/group and directories.
#

# --- Load attributes or fallback to defaults ---
pwquality_path = node['ca']['pwquality'] || '/etc/security/pwquality.conf'
common_pass    = node['ca']['pam_common_password'] || '/etc/pam.d/common-password'
common_auth    = node['ca']['pam_common_auth']     || '/etc/pam.d/common-auth'
dev_dir        = node['ca']['dev_dir'] || '/opt/dev'
group_name     = node['ca']['group']   || 'developers'
user_name      = node['ca']['user']    || 'cogsi'

# --- Ensure PAM pwquality package is installed ---
package 'libpam-pwquality'

# --- Ensure pam_pwhistory rule exists ---
ruby_block 'ensure pam_pwhistory rule' do
  block do
    next unless File.exist?(common_pass)
    text = File.read(common_pass)
    line = 'password requisite pam_pwhistory.so remember=5 use_authtok enforce_for_root'
    unless text.include?(line)
      text.sub!(/^password\s+\[success=1.*pam_unix\.so.*$/) { |m| "#{m}\n#{line}" }
      File.write(common_pass, text)
    end
  end
end

# --- Ensure pam_pwquality rule exists ---
ruby_block 'ensure pam_pwquality rule' do
  block do
    next unless File.exist?(common_pass)
    txt  = File.read(common_pass)
    rule = 'password requisite pam_pwquality.so minlen=12 minclass=3 dictcheck=1 usercheck=1 retry=3 enforce_for_root'
    if txt =~ /^password\s+requisite\s+pam_pwquality\.so/
      txt.gsub!(/^password\s+requisite\s+pam_pwquality\.so.*$/, rule)
    else
      txt << "\n#{rule}\n"
    end
    File.write(common_pass, txt)
  end
end

# --- Update pwquality.conf ---
file pwquality_path do
  content "usercheck = 1\n"
  mode '0644'
  owner 'root'
  group 'root'
end

# --- Insert faillock configuration ---
ruby_block 'insert faillock block in common-auth' do
  block do
    next unless File.exist?(common_auth)
    content = File.read(common_auth)
    blocktxt = <<~EOT
      # BEGIN CHEF MANAGED BLOCK - faillock
      auth required pam_faillock.so preauth silent deny=5 unlock_time=600
      auth [default=die] pam_faillock.so authfail deny=5 unlock_time=600
      account required pam_faillock.so
      # END CHEF MANAGED BLOCK - faillock
    EOT
    unless content.include?('CHEF MANAGED BLOCK - faillock')
      content.sub!(/^auth\s+\[success=1/m, blocktxt + "\n\\0")
      File.write(common_auth, content)
    end
  end
end

# --- Create development group and user ---
group group_name do
  action :create
end

user user_name do
  manage_home true
  shell '/bin/bash'
  password '$6$exampleSalt$D7zE2LD2uQ/nS.NekDYh9o0kZ02puDYRdtT2x4nUoeX7tuH1Gf1cAc4t1G2GvDtx2Th/qg.9s.ZCCnF9b44vG/'
  action :create
end

# --- Add user to group ---
group group_name do
  members [user_name]
  append true
  action :modify
end

# --- Create dev directory ---
directory dev_dir do
  owner 'root'
  group group_name
  mode '0750'
  recursive true
  action :create
end
