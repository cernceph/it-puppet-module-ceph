define ceph::conf::osd (
  $device,
  $cluster_addr,
  $public_addr,
) {

  concat::fragment { "ceph-osd-${::hostname}-${name}.conf":
    tag     => "${ceph::conf::fsid}-ceph.conf",
    target  => '/etc/ceph/ceph.conf',
    order   => '80',
    content => template('ceph/ceph.conf-osd.erb'),
  }

}
