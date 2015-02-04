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

  package { 'ceph-radosgw':
    ensure => present,
  } ->
  ceph::conf::radosgw { $name: 
    rgw_dns_name => $dns_name
  } ->
  # assumes client.admin key is on the gw
  exec { 'ceph-radosgw-keyring':
    command =>"ceph auth get-or-create client.radosgw.${::hostname} osd 'allow rwx' mon 'allow rw' --keyring /etc/ceph/keyring -o /etc/ceph/ceph.client.radosgw.${::hostname}.keyring",
    path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    creates => "/etc/ceph/ceph.client.radosgw.${::hostname}.keyring",
    require => Package['ceph'],
  } ->
  exec { 'wget https://raw.github.com/ceph/ceph/master/src/init-radosgw.sysv -O /etc/init.d/radosgw && /bin/chmod +x /etc/init.d/radosgw':
    creates => '/etc/init.d/radosgw',
  } ->
  service { "radosgw":
    ensure    => running,
    enable    => true,
    provider  => $::ceph::params::service_provider,
    hasstatus => true,
    require   => Exec['ceph-radosgw-keyring']
  }
}
