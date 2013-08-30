# Configure a ceph osd device
#
# == Namevar
# the resource name is the full path to the device to be used.
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
# Copyright 2013 eNovance <licensing@enovance.com>
#

define ceph::osd::device (
) {

  include ceph::osd
  include ceph::conf
  include ceph::params

  $devname = regsubst($name, '.*/', '')
  if $name =~ /by-path/ {
     $partfact = "disk/by-path/${devname}-part1"
     $partname = "${name}-part1"
  } else {
     $partfact = "${devname}1"
     $partname = "${name}1"
  }

  exec { "mktable_gpt_${devname}":
    command   => "parted -a optimal --script ${name} mktable gpt",
    unless    => "parted --script ${name} print|grep -sq 'Partition Table: gpt'",
    logoutput => true,
    require   => Package['parted']
  }

  exec { "mkpart_${devname}":
    command   => "parted -a optimal -s ${name} mkpart ceph 0% 100%",
    unless    => "parted ${name} print | egrep '^ 1.*ceph$'",
    logoutput => true,
    require   => [Package['parted'], Exec["mktable_gpt_${devname}"]]
  }

  exec { "mkfs_${devname}":
    command   => "sleep 5 && mkfs.xfs -f -d agcount=${::processorcount} -l \
size=1024m -n size=64k ${partname}",
    unless    => "xfs_admin -l ${partname}",
    logoutput => true,
    require   => [Package['xfsprogs'], Exec["mkpart_${devname}"]],
  }

  $blkid_uuid_fact = "blkid_uuid_${partfact}"
  $blkid = inline_template('<%= scope.lookupvar(blkid_uuid_fact) or "undefined" %>')

  if $blkid != 'undefined'  and defined( Ceph::Key['admin'] ){
    exec { "ceph_osd_create_${devname}":
      command => "ceph osd create ${blkid}",
      unless  => "ceph osd dump | grep -sq ${blkid}",
      require => Ceph::Key['admin'],
    }

    $osd_id_fact = "ceph_osd_id_${partfact}"
    $osd_id = inline_template('<%= scope.lookupvar(osd_id_fact) or "undefined" %>')

    if $osd_id != 'undefined' {

      ceph::conf::osd { $osd_id:
        device       => $partname,
        cluster_addr => $::ceph::osd::cluster_address,
        public_addr  => $::ceph::osd::public_address,
      }

      $osd_data = regsubst($::ceph::conf::osd_data, '\$id', $osd_id)

      file { $osd_data:
        ensure => directory,
      }

      mount { $osd_data:
        ensure  => present,
        device  => "${partname}",
        fstype  => 'xfs',
        options => 'rw,noatime,inode64,noauto',
        pass    => 0,
        require => [
          Exec["mkfs_${devname}"],
          File[$osd_data]
        ],
      }

      exec { "ceph-osd-mkfs-${osd_id}":
        command => "mount ${osd_data} && ceph-osd -c /etc/ceph/ceph.conf \
-i ${osd_id} \
--mkfs \
--mkkey \
--osd-uuid ${blkid}
",
        creates => "${osd_data}/keyring",
        unless  => "ceph auth list | egrep '^osd.${osd_id}$'",
        require => [
          Mount[$osd_data],
          Concat['/etc/ceph/ceph.conf'],
          ],
      }

      exec { "ceph-osd-register-${osd_id}":
        command => "\
ceph auth add osd.${osd_id} osd 'allow *' mon 'allow rwx' \
-i ${osd_data}/keyring",
        unless  => "ceph auth list | egrep '^osd.${osd_id}$'",
        require => Exec["ceph-osd-mkfs-${osd_id}"],
      }

    }

  }

}
