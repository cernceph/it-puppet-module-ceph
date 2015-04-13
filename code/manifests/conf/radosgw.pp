define ceph::conf::radosgw (
  $rgw_dns_name,
  $rgw_keystone_url                 = undef,
  $rgw_keystone_accepted_roles      = undef,
  $rgw_keystone_token_cache_size    = undef,
  $rgw_keystone_revocation_interval = undef
) {
  concat::fragment { "ceph-radosgw-${::hostname}.conf":
    tag     => "${ceph::conf::fsid}-ceph.conf",
    target  => '/etc/ceph/ceph.conf',
    order   => '70',
    content => template('ceph/ceph.conf-radosgw.erb'),
  }
}
