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

  file {'/etc/facter/facts.d/disks_external.sh':
    ensure => present,
    source => 'puppet:///modules/ceph/disks_external.sh',
    mode => '755'
  }

}

