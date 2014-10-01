define ceph::osd::udevice (
  $journal = undef
) {

  # prepend /dev/ if needed
  $osd_dev = $name =~ /dev/ ? {
    true  => $name,
    false => "/dev/${name}"
  }

  # prepend /dev/ if needed
  $journal_dev = $journal =~ /dev/ ? {
    true  => $journal,
    false => "/dev/${journal}"
  }

  exec { "ceph-disk-prepare-${name}":
    command   => "echo ceph-disk -v prepare ${osd_dev} ${journal_dev}",
    unless    => "ceph-disk list | egrep '^ ${osd_dev}[0-9]+ ceph data'",
    logoutput => true,
  }

}
