class nrpe::packages {
	package { [ "opsview-agent" ]:
		ensure => absent;
	}
        package { [ "nagios-nrpe-server", "nagios-plugins", "nagios-plugins-basic", "nagios-plugins-extra", "nagios-plugins-standard" ]:
                ensure => latest;
        }

        file {
                "/etc/nagios/nrpe_local.cfg":
                        owner => root,
                        group => root,
                        mode => 0644,
                        source => "puppet:///files/nagios/nrpe_local.cfg";
		"/usr/lib/nagios/plugins/check_dpkg":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/nagios/check_dpkg";
        }
}

class nrpe::service {
        service { nagios-nrpe-server:
                require => [ Package[nagios-nrpe-server], File["/etc/nagios/nrpe_local.cfg"], File["/usr/lib/nagios/plugins/check_dpkg"] ],
                subscribe => File["/etc/nagios/nrpe_local.cfg"],
		pattern => "/usr/sbin/nrpe",
                ensure => running;
        }

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
		file { "/etc/sudoers.d/nrpe":
			owner => root,
			group => root,
			mode => 0440,
			content => "
nagios	ALL = (root) NOPASSWD: /usr/bin/arcconf getconfig 1
nagios	ALL = (root) NOPASSWD: /usr/bin/check-raid.py
";
		}
	}
}

class nrpe {
	include nrpe::packages
	include nrpe::service

	# Collect virtual NRPE nagios service checks
	Monitor_service <| tag == "nrpe" |>
}
