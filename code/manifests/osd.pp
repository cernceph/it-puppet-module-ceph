# Configure a ceph osd node
#
# == Parameters
#
# [*osd_addr*] The osd's address.
#   Optional. Defaults to the $ipaddress fact.
#
# == Dependencies
#
# none
#
# == Authors
#
#  François Charlier francois.charlier@enovance.com
#
# == Copyright
#
# Copyright 2012 eNovance <licensing@enovance.com>
#

class ceph::osd (
  $public_address  = $::ipaddress,
  $cluster_address = $::ipaddress,
) {

  include 'ceph::package'

  ensure_packages( [ 'xfsprogs', 'parted' ] )

  # patch ceph-disk with latest
  file {'/usr/sbin/ceph-disk':
    ensure => present,
    source => 'puppet:///modules/ceph/ceph-disk',
    mode => '755'
  }
  -> # put this before the fact so we don't try to create an osd too early
  file {'/etc/facter/facts.d/disks_external.sh':
    ensure => present,
    source => 'puppet:///modules/ceph/disks_external.sh',
    mode => '755'
  }

  file {'/etc/rc.d/rc.local':
    ensure => present,
    source => 'puppet:///modules/ceph/osd-rc.local',
    mode => '755'
  }

  # http://tracker.ceph.com/issues/6142
  sysctl { 'kernel.pid_max': val => 4194303 }
}

