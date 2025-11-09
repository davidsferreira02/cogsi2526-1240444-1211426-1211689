name             'ca_stack'
maintainer       'you'
maintainer_email 'you@example.com'
license          'All Rights Reserved'
description      'Provisions CA4 Spring app and H2 database'
version          '0.2.0'
chef_version     '>= 16.0'

supports         'ubuntu'

recipe 'ca_stack::pam_policy', 'Apply PAM and password policy'
recipe 'ca_stack::app', 'Provision Spring Boot application host'
recipe 'ca_stack::h2', 'Provision H2 database host'
