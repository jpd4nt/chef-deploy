
action :create do
  magento[site]['repo_path'] = node['nt-deploy']['sites'][site]['repo_path']
  magento[site]['repo_tag'] = node['nt-deploy']['sites'][site].fetch('repo_tag', false)
  magento[site]['repo_branch'] = node['nt-deploy']['sites'][site].fetch('repo_branch', 'develop')
  magento[site]['site_path'] = node['nt-deploy']['sites'][site].fetch('site_path', '/var/www')
  magento[site]['repo_user'] = node['nt-deploy']['sites'][site].fetch('repo_user', 'git')
  magento[site]['site_type'] = node['nt-deploy']['sites'][site].fetch('site_type', 'magento')
  
  execute 'clear_repo_path' do
    command "rm -rf #{magento[site]['site_path']}/#{site}"
    only_if { ::File.exists?("#{magento[site]['site_path']}/#{site}/magento/index.html")}
    not_if {::File.exists?("#{magento[site]['site_path']}/#{site}/.git")}
  end
  
  execute 'clone_site' do
    command "git clone #{magento[site]['repo_user']}@#{site}:#{magento[site]['repo_path']} #{magento[site]['site_path']}/#{site}"
  end
  
  execute 'checkout_branch' do
    cwd "#{magento[site]['site_path']}/#{site}"
    command "git checkout -b #{magento[site]['repo_branch']} origin/#{magento[site]['repo_branch']}; git pull"
  end
  
  execute 'checkout_branch' do
    cwd "#{magento[site]['site_path']}/#{site}"
    command "git fetch origin; git checkout -b #{magento[site]['repo_tag']} tags/#{magento[site]['repo_tag']}"
  end
  
  magento[site]['vhost'] = node['nt-deploy']['sites'][site].fetch('vhost', 'default')
  magento[site]['db_name'] = node['nt-deploy']['sites'][site].fetch('db_name', "magento_#{site}")
  magento[site]['db_user'] = node['nt-deploy']['sites'][site].fetch('db_user', site)
  magento[site]['db_pwd'] = node['nt-deploy']['sites'][site].fetch('db_pwd', site)
  magento[site]['db_host'] = node['nt-deploy']['sites'][site].fetch('db_host', node['nt-deploy']['default']['db_host'])
  magento[site]['elb'] = node['nt-deploy']['sites'][site].fetch('elb', node['nt-deploy']['default']['elb'])
  magento[site]['salt'] = node['nt-deploy']['sites'][site].fetch('salt', '')
  magento[site]['cache_prefix'] = node['nt-deploy']['sites'][site].fetch('cache_prefix', "#{site}_")
  magento[site]['sites_caches'] = node['nt-deploy']['sites'][site].fetch('sites_caches', [])
  
  magento[site]['site_dns'] = node['nt-deploy']['sites'][site].fetch('site_dns', 'www.example.net')
  magento[site]['admin_url'] = node['nt-deploy']['sites'][site].fetch('admin_url', 'admin')
  magento[site]['cron_key'] = node['nt-deploy']['sites'][site].fetch('cron_key', 'cron-key')
  
  directory "/media/ephemeral0/tmp/#{site}" do
    owner 'apache'
    group 'apache'
    mode '0755'
    action :create
    recursive true
  end
  
  selinux_policy_fcontext "/media/ephemeral0/tmp/#{site}(/.*)?" do
    secontext 'httpd_sys_rw_content_t'
  end
  
  selinux_policy_fcontext "#{magento[site]['site_path']}/#{site}/magento(/.*)?" do
    secontext 'httpd_sys_content_t'
  end
  
  selinux_policy_fcontext "#{magento[site]['site_path']}/#{site}/magento(/.*)\.php?" do
    secontext 'httpd_user_script_exec_t'
  end
  
  selinux_policy_fcontext "#{magento[site]['site_path']}/#{site}/magento/media(/.*)?" do
    secontext 'httpd_sys_rw_content_t'
  end
  
  selinux_policy_fcontext "#{magento[site]['site_path']}/#{site}/magento/var(/.*)?" do
    secontext 'httpd_sys_rw_content_t'
  end
  
  selinux_policy_fcontext "#{magento[site]['site_path']}/#{site}/magento/xmlfile.xml" do
    secontext 'httpd_sys_rw_content_t'
  end
  
  %w{app dev downloader downloaderntmgt errors includes js lib newslettersucess pkginfo shell skin var}.each do |folder|
    directory "#{magento[site]['site_path']}/#{site}/magento/#{folder}" do
      owner 'apache'
      group 'apache'
      mode '0755'
      recursive true
      action :create
    end
  end
  Dir.foreach("#{magento[site]['site_path']}/#{site}/magento") do |item|
    next if item == '.' or item == '..' or File.directory?("#{magento[site]['site_path']}/#{site}/magento/#{item}")
    file "#{magento[site]['site_path']}/#{site}/magento/#{item}" do
      mode '0644'
      owner 'apache'
      group 'apache'
    end
  end
  
  template "#{magento[site]['site_path']}/#{site}/magento/app/etc/local.xml" do
    source "local.xml.erb"
    mode '0440'
    owner 'apache'
    group 'apache'
    variables ({
      :db_name   => magento[site]['db_name'],
      :db_user   => magento[site]['db_user'],
      :db_pwd    => magento[site]['db_pwd'],
      :db_host   => magento[site]['db_host'],
      :salt      => magento[site]['salt'],
      :admin_url => magento[site]['admin_url']
    })
  end
end
