define ceph::conf::mds (
  $mds_data
) {

  @@concat::fragment { "ceph-mds-${name}.conf":
    tag     => "${ceph::conf::fsid}-ceph.conf",
    target  => '/etc/ceph/ceph.conf',
    order   => '60',
    content => template('ceph/ceph.conf-mds.erb'),
  }

}
