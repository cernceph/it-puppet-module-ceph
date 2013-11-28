define ceph::conf::mds (
) {

  concat::fragment { "ceph-mds-${::hostname}.conf":
    tag     => "${ceph::conf::fsid}-ceph.conf",
    target  => '/etc/ceph/ceph.conf',
    order   => '70',
    content => template('ceph/ceph.conf-mds.erb'),
  }

}
