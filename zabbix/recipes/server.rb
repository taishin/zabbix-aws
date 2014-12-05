#
# Cookbook Name:: zabbix
# Recipe:: server
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "zabbix::default"

case node[:platform]
when "amazon"
  node['zabbix']['server']['packages'].each do |pkg|
    package pkg do
      if node['zabbix']['version']['full']
        version "#{node['zabbix']['version']['full']}.el6"
      end
      action :install
    end
  end

  package "ruby20-devel" do
    action :install
  end

#  execute "alternatives-ruby" do
#    command "/usr/sbin/alternatives --set ruby /usr/bin/ruby1.9"
#  end

  httpd_conf_template = "httpd.conf.azn.erb"

end

node['zabbix']['other']['packages'].each do |pkg|
  package pkg do
    action :install
  end
end

node['zabbix']['server']['gems'].each do |pkg|
  gem_package pkg do
    action :install
    options("--no-ri --no-rdoc")
  end
end

execute "create-database-user" do
  exists = <<-EOH
mysql -u #{node['zabbix']['db']['user']} -p#{node['zabbix']['db']['password']} -h #{node['zabbix']['db']['host']} #{node['zabbix']['db']['name']} -e 'show tables like "maintenances";' | grep -c maintenances
EOH
  command <<-EOH
mysql -u #{node['zabbix']['db']['user']} -p#{node['zabbix']['db']['password']} -h #{node['zabbix']['db']['host']} #{node['zabbix']['db']['name']} < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/schema.sql
mysql -u #{node['zabbix']['db']['user']} -p#{node['zabbix']['db']['password']} -h #{node['zabbix']['db']['host']} #{node['zabbix']['db']['name']} < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/images.sql
mysql -u #{node['zabbix']['db']['user']} -p#{node['zabbix']['db']['password']} -h #{node['zabbix']['db']['host']} #{node['zabbix']['db']['name']} < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/data.sql
EOH
  not_if exists
end


#script "create_zabbix_table" do
#  interpreter "bash"
#  user "root"
#  code <<-EOH
#mysql -u zabbix -ppassword -h #{node['zabbix']['db']['host']} zabbix < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/schema.sql
#mysql -u zabbix -ppassword -h #{node['zabbix']['db']['host']} zabbix < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/images.sql
#mysql -u zabbix -ppassword -h #{node['zabbix']['db']['host']} zabbix < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/data.sql
#EOH
#end


template "/etc/zabbix/zabbix_server.conf" do
  source "zabbix_server.conf-#{node['zabbix']['version']['major']}.erb"
  owner "root"
  notifies :restart, "service[zabbix-server]"
  mode 0640
end

template "/etc/zabbix/web/zabbix.conf.php" do
  source "zabbix.conf.php.erb"
  owner "root"
  notifies :restart, "service[zabbix-server]"
  mode 0644
end

template "/etc/php.ini" do
  source "php.ini.erb"
  owner "root"
  notifies :restart, "service[httpd]"
  mode 0644
end

template "/etc/httpd/conf/httpd.conf" do
  source httpd_conf_template
  owner "root"
  notifies :restart, "service[httpd]"
  mode 0644
end

if node[:platform] == "amazon"
  template "/etc/httpd/conf.d/zabbix.conf" do
    source "zabbix.conf.erb"
    owner "root"
    notifies :restart, "service[httpd]"
    mode 0644
  end
end


service "zabbix-server" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

service "httpd" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

service "iptables" do
  supports :status => true, :restart => true, :reload => true
  action [ :disable, :stop ]
end

service "ip6tables" do
  supports :status => true, :restart => true, :reload => true
  action [ :disable, :stop ]
end

git "#{Chef::Config[:file_cache_path]}/zabbix-api" do
	repository "https://github.com/taishin/zabbix-api.git"
	reference "master"
	action :checkout
end

bash "exec zbxapi" do
	cwd "#{Chef::Config[:file_cache_path]}/zabbix-api"
	code <<-EOC
	  find . -name "*.rb" -exec ruby {} \\;
	EOC
end
