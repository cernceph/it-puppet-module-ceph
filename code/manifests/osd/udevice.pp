define ceph::osd::udevice (
  $journal = ''
) {

  if $name =~ /dev/ {
    $osd_dev = $name
  } else {
    $osd_dev = "/dev/${name}"
  }

  if $journal == '' or $journal =~ /dev/ {
    $journal_dev = $journal
  } else {
    $journal_dev = "/dev/${journal}"
  }

  exec { "ceph-disk-prepare-${name}":
    command   => "echo ceph-disk -v prepare ${osd_dev} ${journal_dev}",
    unless    => "ceph-disk list | egrep '^ ${osd_dev}[0-9]+ ceph'",
    logoutput => true,
  }

}
