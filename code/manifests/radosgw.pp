# Configure a ceph radosgw
#
# == Name
#   This resource's name is generally the hostname
# == Parameters
# [*monitor_secret*] See mon.pp
#   Mandatory.
#
# [*admin_email*] Email address for apache server admin
#   Optional. Defaults to root@localhost
#
# == Dependencies
#
# none
#
# == Authors
#
#  Dan van der Ster daniel.vanderster@cern.ch
#
# == Copyright
#
# Copyright 2013 CERN
#

define ceph::radosgw (
  $admin_email = 'root@localhost',
  $dns_name    = undef
) {

  include 'ceph::package'
  include 'ceph::conf'
  include 'ceph::params'

  ensure_packages( [ 'mod_ssl', 'httpd', 'ceph-radosgw', 'mod_fastcgi' ] )

  Yumrepo['httpd-ceph'] -> Yumrepo['fastcgi-ceph'] -> Package['mod_ssl'] -> Package['httpd'] -> Package['mod_fastcgi'] -> Package['ceph-radosgw']

  ceph::conf::radosgw { $name: 
    rgw_dns_name => $dns_name
  }

  # assumes client.admin key is on the gw
  exec { 'ceph-radosgw-keyring':
    command =>"ceph auth get-or-create client.radosgw.${::hostname} osd 'allow rwx' mon 'allow rw' --keyring /etc/ceph/keyring -o /etc/ceph/ceph.client.radosgw.${::hostname}.keyring",
    path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    creates => "/etc/ceph/ceph.client.radosgw.${::hostname}.keyring",
    before  => Service["radosgw"],
    require => Package['ceph'],
  }

  exec { 'wget https://raw.github.com/ceph/ceph/master/src/init-radosgw.sysv -O /etc/init.d/radosgw && /bin/chmod +x /etc/init.d/radosgw':
    creates => '/etc/init.d/radosgw',
    before  => Service['radosgw']
  }

  file { '/var/log/radosgw':
    ensure => 'directory',
    before => Service['radosgw']
  }

  service { "radosgw":
    ensure    => running,
    enable    => true,
    provider  => $::ceph::params::service_provider,
    hasstatus => false,
    require   => Exec['ceph-radosgw-keyring']
  }

  augeas{ 'turn_fastcgiwrapper_off':
    context => '/files/etc/httpd/conf.d/fastcgi.conf',
    changes => "set *[self::directive='FastCgiWrapper']/arg Off",
    require => Package['mod_fastcgi'],
    notify  => Service['httpd']
  }

  file { '/etc/httpd/conf.d/rgw.conf':
    content => template('ceph/rgw.conf.erb'),
    require => Package['httpd'],
    notify  => Service['httpd']
  }
  
  file { '/var/www/s3gw.fcgi':
    content => template('ceph/s3gw.fcgi.erb'),
    mode    => '0755',
    require => Package['httpd'],
    notify  => Service['httpd']
  }

  file { '/etc/httpd/conf.d/ssl.conf':
    content => template('ceph/ssl.conf.erb'),
    require => Package['mod_ssl'],
    notify  => Service['httpd']
  }

  service { 'httpd':
    ensure  => running,
    enable  => true,
    require => [File['/etc/httpd/conf.d/rgw.conf'], File['/var/www/s3gw.fcgi'],
      Package['mod_fastcgi'], Augeas['turn_fastcgiwrapper_off']]
  }

}
