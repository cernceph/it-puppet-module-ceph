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
    command   => "ceph-disk -v prepare ${osd_dev} ${journal_dev}",
    unless    => "stat $(egrep '${osd_dev}[0-9]+' /proc/mounts | cut -d' ' -f2)/whoami || parted ${osd_dev} print | egrep 'ceph|boot|raid|xfs|ext4'",
    logoutput => true,
  }

}
