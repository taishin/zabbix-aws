default['zabbix']['version']['major'] = "2.4"
# default['zabbix']['version']['full'] = "2.2.0-1"
default['zabbix']['packages'] = %w{
	zabbix
	zabbix-agent
	zabbix-sender
}

default['zabbix']['agent']['serverip'] = "172.24.2.8,10.3.113.8"



default['zabbix']['server']['packages'] = %w{
	zabbix-get
	zabbix-server-mysql
	zabbix-web-mysql
	zabbix-web-japanese
}


default['zabbix']['other']['packages'] = %w{
	mysql
	git
	crontabs
	ntp
	tcpdump
	telnet
	vim-enhanced
	bind-utils
	man
	mlocate
	zlib-devel
	gcc
	make
	zip
	libyaml
	libxslt-devel
	libxml2-devel
	mailx
}

default['zabbix']['server']['gems'] = %w{
	zabbix-client	
	zipruby
}


default['zabbix']['snmp']['packages'] = %w{
        net-snmp-utils
        net-snmp-perl
}

default['zabbix']['snmp']['mibpath'] = "/usr/share/snmp/mibs"

default['zabbix']['java']['packages'] = %w{
        zabbix-java-gateway
}

default['zabbix']['proxy']['packages'] = %w{
	zabbix-get
        zabbix-proxy-pgsql
}

default['zabbix']['full']['packages'] = %w{
        monit
}

default['zabbix']['full']['gems'] = %w{
	nokogiri
	thinreports
	mail
}

default['ntp']['servers'] = %w{ntp.nict.jp}
case platform
  when "redhat", "centos", "fedora"
    default['ntp']['service'] = "ntpd"
  when "ubuntu"
    default['ntp']['service'] = "ntp"
end

default['monit']['mailserver'] = "localhost"
default['monit']['fromaddress'] = "monit@localhost"
default['monit']['toaddress'] = %w{
	root@localhost
}
