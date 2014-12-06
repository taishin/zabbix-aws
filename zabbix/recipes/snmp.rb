#
# Cookbook Name:: zabbix
# Recipe:: server
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
node['zabbix']['snmp']['packages'].each do |pkg|
  package pkg do
    action :install
    options "--enablerepo=epel"
  end
end

if node[:platform] == 'amazon' then
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

  %w{
    openssl-devel
    gcc
    gcc-c++
    net-snmp
    perl-IPC-Cmd
    perl-CPAN-Meta
    perl-Sys-Syslog
    cpan
  }.each do |pkg|
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

#  directory "/var/spool/snmptt" do
#    owner 'root'
#    group 'root'
#    mode '0744'
#    action :create
#  end

else
  package "snmptt" do
    action :install
  end
end
  

git "#{node['zabbix']['snmp']['mibpath']}/vendor_mibs" do
	repository "https://github.com/taishin/vendor_mibs.git"
	reference "master"
	action :checkout
end


bash "create snmptt.conf for vendor mibs" do
	code <<-EOC
	  CONF=/etc/snmp/snmptt.conf.vendors
	  TMPFILE=#{Chef::Config[:file_cache_path]}/snmptt.conf.vendors.tmp
	  MIBDIR=#{node['zabbix']['snmp']['mibpath']}/vendor_mibs
	  for file in $( ls $MIBDIR ); do
	    /usr/bin/snmpttconvertmib --in=$MIBDIR\/$file \
	    --out=$TMPFILE \
	    --net_snmp_perl
	  done
	  sed -e "s/^FORMAT\s/FORMAT ZBXTRAP \\$aA /g" $TMPFILE > $CONF
	  rm $TMPFILE
	EOC
  not_if { ::FileTest.exist?("/etc/snmp/snmptt.conf.vendors") }
  notifies :restart, "service[snmptt]"
end

template "/etc/snmp/snmptrapd.conf" do
  source "snmptrapd.conf.erb"
  owner "root"
  notifies :restart, "service[snmptrapd]"
  mode 0644
end

template "/etc/sysconfig/snmptrapd" do
  source "snmptrapd.erb"
  owner "root"
  notifies :restart, "service[snmptrapd]"
  mode 0644
end

template "/etc/snmp/snmptt.conf" do
  source "snmptt.conf.erb"
  owner "root"
  notifies :restart, "service[snmptt]"
  mode 0644
end

template "/etc/snmp/snmptt.ini" do
  source "snmptt.ini.erb"
  owner "root"
  notifies :restart, "service[snmptt]"
  mode 0644
end

template "/etc/snmp/snmp.conf" do
  source "snmp.conf.erb"
  owner "root"
  mode 0644
end

service "snmptrapd" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

service "snmptt" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
