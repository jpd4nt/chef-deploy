#
# Cookbook Name:: nt-deploy
# Recipe:: bookshop_live
#
# Copyright 2015, National Theatre
#
# All rights reserved - Do Not Redistribute
#

service "httpd" do
  action :nothing
end

selinux_policy_boolean 'httpd_can_network_connect' do
    value true
    notifies :restart,'service[httpd]', :delayed
end

package 'nfs-utils'
package 'cachefilesd'
service "cachefilesd" do
  action [:enable, :start]
end

Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)      
command = 'curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone'
command_out = shell_out(command)
region = command_out.stdout

directory "/var/www/bookshop" do
    owner 'apache'
    group 'apache'
    mode '0755'
    action :create
    recursive true
  end

mount 'code_base' do
    device "#{region}.fs-33678afa.efs.eu-west-1.amazonaws.com:/"
    fstype 'nfs4'
    mount_point '/var/www/bookshop'
    action [:enable, :mount]
    options "noatime,nfsvers=4.1,fsc,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2"
end

selinux_policy_boolean 'httpd_use_nfs' do
    value true
    notifies :restart,'service[httpd]', :delayed
end

package 'unzip'

execute 'unzip_code' do
  cwd     '/var/www/bookshop'
  command "unzip -q -o #{node['nt-deploy']['bookshop_version']}.zip"
  action  :nothing
  notifies :restart,'service[httpd]', :delayed
end

include_recipe 's3_file::dependencies'

s3_file "/var/www/bookshop/#{node['nt-deploy']['bookshop_version']}.zip" do
    remote_path "/Bookshop/#{node['nt-deploy']['bookshop_version']}.zip"
    bucket "live-codeartifacts"
    s3_url "https://s3-eu-west-1.amazonaws.com/live-codeartifacts"
    mode "0644"
    action :create
    notifies :run, 'execute[unzip_code]', :immediately
    not_if {  ::File.exists?("/var/www/bookshop/#{node['nt-deploy']['bookshop_version']}.zip") }
end

cookbook_file '/opt/rh/php55/root/etc/php.d/10-opcache.ini' do
  source 'opcache-magento.ini'
  owner 'apache'
  group 'apache'
  mode '0644'
  action :create
  notifies :restart,'service[httpd]', :delayed
end

template '/etc/httpd/conf.modules.d/01-prefork.conf' do
  source 'prefork.conf.erb'
  notifies :restart,'service[httpd]', :delayed
end

keys = data_bag('bookshop')

nt_deploy_magento "bookshop" do
    use_bundle true
    site_dns 'shop.nationaltheatre.org.uk'
    db_user 'bookshop'
    db_pwd data_bag_item('bookshop', 'live')['pwd']
    cache_prefix 'bs_'
    salt data_bag_item('bookshop', 'live')['salt']
    admin_url 'ntmgtaccesslink'
end

%w{Aitoc_Aitreports.xml Aitoc_Common.xml Aitoc_Aitinstall.xml}.each do |folder|
    file "/var/www/bookshop/magento/app/etc/modules/#{folder}" do
      owner 'apache'
      group 'apache'
      mode '0664'
    end
    selinux_policy_fcontext "/var/www/bookshop/magento/app/etc/modules/#{folder}" do
      secontext 'httpd_sys_rw_content_t'
    end
end


