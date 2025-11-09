# ===== Default CA Stack attributes =====

# PAM-related files
default['ca']['pam_common_password'] = '/etc/pam.d/common-password'
default['ca']['pam_common_auth']     = '/etc/pam.d/common-auth'
default['ca']['pwquality']           = '/etc/security/pwquality.conf'

# User and group configuration
default['ca']['group'] = 'developers'
default['ca']['user']  = 'cogsi'

# Application & DB connectivity
default['ca']['app_project_dir'] = '/workspace/CA2/Part2'
default['ca']['build_app']       = true
default['ca']['start_app']       = true
default['ca']['app_port']        = 8080
default['ca']['app_ip']          = '192.168.56.11'
default['ca']['db_ip']           = '192.168.56.10'
default['ca']['dev_dir']         = '/opt/developers'

# H2 database
default['ca']['h2_version']         = '2.2.224'
default['ca']['start_db']           = true
default['ca']['h2_port']            = 9092
# Health-check timeout (seconds) for H2 TCP port readiness
default['ca']['h2_health_timeout']  = 60
