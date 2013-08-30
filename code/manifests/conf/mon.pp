define ceph::conf::mon (
  $mon_addr,
  $mon_port,
) {

  @@concat::fragment { "ceph-mon-${::hostname}.conf":
    tag     => "${ceph::conf::fsid}-ceph.conf",
    target  => '/etc/ceph/ceph.conf',
    order   => '50',
    content => template('ceph/ceph.conf-mon.erb'),
  }

}
