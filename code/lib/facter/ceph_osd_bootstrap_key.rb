# Fact: ceph_osd_bootstrap_key
#
# Purpose:
#
# Resolution:
#
# Caveats:
#

require 'facter'
require 'timeout'

timeout = 10

## blkid_uuid_#{device} / ceph_osd_id_#{device}
## Facts that export partitions uuids & ceph osd id of device

# Load the osds/uuids from ceph

# run blkid once on the by-path entries to ensure blkid.tab is correct
Facter::Util::Resolution.exec("blkid /dev/disk/by-path/*")

begin
  Timeout::timeout(timeout) {
    ceph_health = Facter::Util::Resolution.exec("ceph health 2>&1 | grep 'Error connecting to cluster'")
    if ceph_health !~ /Error connecting to cluster/
      ceph_osds = Hash.new
      ceph_osd_dump = Facter::Util::Resolution.exec("ceph osd dump")
      ceph_osd_dump and ceph_osd_dump.each_line do |line|
        if line =~ /^osd\.(\d+).* ([a-f0-9\-]+)$/
          ceph_osds[$2] = $1
        end
      end

      blkid = Facter::Util::Resolution.exec("blkid")
      blkid and blkid.each_line do |line|
        if line =~ /^\/dev\/(.+):.*UUID="([a-fA-F0-9\-]+)"/
          devicetmp = $1
          uuid = $2
          device = devicetmp.gsub(/sas-0x[0-9a-f]+([0-9a-f]{2})-lun/,'sas-\1-lun')

          Facter.add("blkid_uuid_#{device}") do
            setcode do
              uuid
            end
          end

          Facter.add("ceph_osd_id_#{device}") do
            setcode do
              ceph_osds[uuid]
            end
          end
        end
      end
    end
  }
rescue Timeout::Error
  Facter.warnonce('ceph command timeout in ceph_osd_bootstrap_key fact')
end
