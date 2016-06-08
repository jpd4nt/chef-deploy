#
# Cookbook Name:: nt-deploy
# Recipe:: deploy_ntother_live
#
# Copyright 2016, National Theatre
#
# All rights reserved - Do Not Redistribute
#

directory "/root/.composer" do
  mode '0755'
  action :create
end
template "/root/.composer/auth.json" do
  source "auth.json.erb"
  mode '0600'
  variables ({
    :token => node['nt-deploy']['github']
  })
end

mysql2_chef_gem 'default' do
  action :install
end

directory '/mnt/data-store/NTOther' do
  owner 'apache'
  group 'apache'
  mode  '0755'
  action :create
end

execute 'unzip_code' do
  cwd     '/mnt/data-store'
  command 'unzip -q -o NTOtherDrupal.zip'
  action  :nothing
end

include_recipe 's3_file::dependencies'

s3_file "/mnt/data-store/NTOther/NTOtherDrupal.zip" do
    remote_path "/NTOtherDrupal/v1.0.0.zip"
    bucket "my-s3-bucket"
    s3_url "https://s3-eu-west-1.amazonaws.com/bucket"
    mode "0644"
    action :create
    notifies :run, 'execute[unzip_code]', :immediately
end

keys = data_bag('ntother_live')

nt_deploy "linburyprize" do
    site_label 'NTMicrosites'
    repo_path 'National-Theatre/NT-Web-Hosting.git'
    repo_branch 'master'
    site_dns 'linburyprize.cms.nationaltheatre.org.uk'
    vhost 'linburyprize'
    db_user 'linburyprize'
    db_pwd data_bag_item('ntother_live', 'linburyprize')['pwd']
    cache_prefix 'lby_'
    salt data_bag_item('ntother_live', 'linburyprize')['salt']
    cron_key data_bag_item('ntother_live', 'linburyprize')['cron']
    cache_type 'Redis_Cache'
    sites_caches ['sites/all/modules/contrib/redis/redis.autoload.inc']
end

nt_deploy "newviews" do
    site_label 'NTMicrosites'
    repo_path 'National-Theatre/NT-Web-Hosting.git'
    repo_branch 'master'
    site_dns 'new-views.cms.nationaltheatre.org.uk'
    vhost 'newviews'
    db_user 'newviews'
    db_pwd data_bag_item('ntother_live', 'newviews')['pwd']
    cache_prefix 'nv_'
    salt data_bag_item('ntother_live', 'newviews')['salt']
    cron_key data_bag_item('ntother_live', 'newviews')['cron']
    cache_type 'Redis_Cache'
    sites_caches ['sites/all/modules/contrib/redis/redis.autoload.inc']
end

nt_deploy "ntfuture" do
    site_label 'NTMicrosites'
    repo_path 'National-Theatre/NT-Web-Hosting.git'
    repo_branch 'master'
    site_dns 'ntfuture.cms.nationaltheatre.org.uk'
    vhost 'ntfuture'
    db_user 'ntfuture'
    db_pwd data_bag_item('ntother_live', 'ntfuture')['pwd']
    cache_prefix 'ntf_'
    salt data_bag_item('ntother_live', 'ntfuture')['salt']
    cron_key data_bag_item('ntother_live', 'ntfuture')['cron']
    cache_type 'Redis_Cache'
    sites_caches ['sites/all/modules/contrib/redis/redis.autoload.inc']
end

nt_deploy "allabouttheatre" do
    site_label 'NTMicrosites'
    repo_path 'National-Theatre/NT-Web-Hosting.git'
    repo_branch 'master'
    site_dns 'allabouttheatre.cms.nationaltheatre.org.uk'
    vhost 'allabouttheatre'
    db_user 'allabouttheatre'
    db_pwd data_bag_item('ntother_live', 'allabouttheatre')['pwd']
    cache_prefix 'abt_'
    salt data_bag_item('ntother_live', 'allabouttheatre')['salt']
    cron_key data_bag_item('ntother_live', 'allabouttheatre')['cron']
    cache_type 'Redis_Cache'
    sites_caches ['sites/all/modules/contrib/redis/redis.autoload.inc']
end
