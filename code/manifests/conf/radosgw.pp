define ceph::conf::radosgw (
  $rgw_dns_name
) {

  concat::fragment { "ceph-radosgw-${::hostname}.conf":
    tag     => "${ceph::conf::fsid}-ceph.conf",
    target  => '/etc/ceph/ceph.conf',
    order   => '70',
    content => template('ceph/ceph.conf-radosgw.erb'),
  }

}
