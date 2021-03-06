name             'nt-deploy'
maintainer       'National Theatre'
maintainer_email 'jdrawneek@nationaltheatre.org.uk'
license          'All rights reserved'
description      'Installs/Configures nt-deploy'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.5.14'
depends          'ssh_known_hosts'
depends          'cron'
depends          'hostsfile'
depends          'selinux_policy', '>= 0.9.2'
depends          'database', '~> 4.0.9'
depends          'mysql2_chef_gem', '~> 1.0'
depends          's3_file'
