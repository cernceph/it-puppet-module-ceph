class ceph::yum::rgw () {
  yumrepo { 'httpd-ceph':
    descr    => "Apache packages for Ceph",
    baseurl  => "http://gitbuilder.ceph.com/apache2-rpm-rhel6-x86_64-basic/ref/master",
    enabled  => 1,
    priority => 2,
    gpgcheck => 1,
    gpgkey   =>
      'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc',
  }

  yumrepo { 'fastcgi-ceph':
    descr    => "FastCGI packages for Ceph",
    baseurl  => "http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel6-x86_64-basic/ref/master",
    enabled  => 1,
    priority => 2,
    gpgcheck => 1,
    gpgkey   =>
      'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc',
  }
}
