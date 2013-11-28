# Configure a ceph mds
#
# == Name
#   This resource's name is the mon's id and must be numeric.
# == Parameters
# [*fsid*] The cluster's fsid.
#   Mandatory. Get one with `uuidgen -r`.
#
# [*auth_type*] Auth type.
#   Optional. undef or 'cephx'. Defaults to 'cephx'.
#
# [*mds_data*] Base path for mon data. Data will be put in a mon.$id folder.
#   Optional. Defaults to '/var/lib/ceph/mds.
#
# == Dependencies
#
# none
#
# == Authors
#
#  Sébastien Han sebastien.han@enovance.com
#  François Charlier francois.charlier@enovance.com
#
# == Copyright
#
# Copyright 2012 eNovance <licensing@enovance.com>
#

define ceph::mds (
  $auth_type = 'cephx',
  $mds_data = '/var/lib/ceph/mds',
) {

  include 'ceph::package'
  include 'ceph::params'

  ceph::conf::mds { $name: }

  $mds_data_expanded = "${mds_data}/mds.${name}"

  file { $mds_data_expanded:
    ensure  => directory,
    owner   => 'root',
    group   => 0,
    mode    => '0755',
  }

  exec { 'ceph-mds-keyring':
    command => "ceph auth get-or-create mds.${name} mds 'allow ' osd 'allow *' mon 'allow rwx' > /var/lib/ceph/mds/mds.${name}/keyring",
    creates => "/var/lib/ceph/mds/mds.${name}/keyring",
    require => [Package['ceph'], File[$mds_data_expanded]],
  }

}
