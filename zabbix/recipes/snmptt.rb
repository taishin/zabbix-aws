#
# Cookbook Name:: zabbix
# Recipe:: server
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#

user "snmptt" do
  supports :manage_home => true
  comment "SNMP Trap Translator"
  system true
  shell "/sbin/nologin"
  home "/var/spool/snmptt"
end

directory "/var/spool/snmptt" do
  mode '0755'
end

%w{ openssl-devel git gcc gcc-c++ net-snmp perl-IPC-Cmd perl-CPAN-Meta perl-Sys-Syslog }
.each do |pkg|
  package "#{pkg}" do
    action 'install'
  end
end

%w{
  Module::Build::Compat
  Config::IniFiles
}.each do |mod|
  cpan_client "#{mod}" do
    action 'install'
    install_type 'cpan_module'
    user 'root'
    group 'root'
  end
end

remote_file "#{Chef::Config[:file_cache_path]}/snmptt.tgz" do
  source "http://sourceforge.net/projects/snmptt/files/latest/download?source=files"
end

execute "install_snmptt" do
  exists = <<-EOH
which snmptt
EOH
  command <<-EOH
tar xzvf #{Chef::Config[:file_cache_path]}/snmptt.tgz -C #{Chef::Config[:file_cache_path]}
cp #{Chef::Config[:file_cache_path]}/snmptt_1.4/snmptt /usr/sbin
cp #{Chef::Config[:file_cache_path]}/snmptt_1.4/snmptthandler /usr/sbin
cp #{Chef::Config[:file_cache_path]}/snmptt_1.4/snmpttconvert /usr/bin
cp #{Chef::Config[:file_cache_path]}/snmptt_1.4/snmpttconvertmib /usr/bin
cp #{Chef::Config[:file_cache_path]}/snmptt_1.4/snmptt-net-snmp-test /usr/bin
cp #{Chef::Config[:file_cache_path]}/snmptt_1.4/snmptt.logrotate /etc/logrotate.d/snmptt
cp #{Chef::Config[:file_cache_path]}/snmptt_1.4/snmptt.ini /etc/snmp/
cp #{Chef::Config[:file_cache_path]}/snmptt_1.4/snmptt-init.d /etc/init.d/snmptt
/sbin/chkconfig --add snmptt
EOH
  not_if exists
end
#execute "create-database-user" do
#  exists = <<-EOH
#mysql -u #{node['zabbix']['db']['user']} -p#{node['zabbix']['db']['password']} -h #{node['zabbix']['db']['host']} #{node['zabbix']['db']['name']} -e 'show tables like "maintenances";' | grep -c maintenances
#EOH
#  command <<-EOH
#mysql -u #{node['zabbix']['db']['user']} -p#{node['zabbix']['db']['password']} -h #{node['zabbix']['db']['host']} #{node['zabbix']['db']['name']} < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/schema.sql
#mysql -u #{node['zabbix']['db']['user']} -p#{node['zabbix']['db']['password']} -h #{node['zabbix']['db']['host']} #{node['zabbix']['db']['name']} < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/images.sql
#mysql -u #{node['zabbix']['db']['user']} -p#{node['zabbix']['db']['password']} -h #{node['zabbix']['db']['host']} #{node['zabbix']['db']['name']} < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/data.sql
#EOH
#  not_if exists
#end


#script "create_zabbix_table" do
##  interpreter "bash"
##  user "root"
##  code <<-EOH
##mysql -u zabbix -ppassword -h #{node['zabbix']['db']['host']} zabbix < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/schema.sql
##mysql -u zabbix -ppassword -h #{node['zabbix']['db']['host']} zabbix < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/images.sql
##mysql -u zabbix -ppassword -h #{node['zabbix']['db']['host']} zabbix < /usr/share/doc/`rpm -q zabbix-server-mysql | sed -e s/-.\.el.\.x86_64//`/create/data.sql
##EOH
##end
#
