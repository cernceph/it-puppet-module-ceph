require 'spec_helper'

describe 'ceph::osd::device' do

  let :title do
    '/dev/device'
  end

  let :pre_condition do
    "class { 'ceph::conf': fsid => '12345', osd_crush_location => 'room=dummy-room' }
class { 'ceph::osd':
  public_address  => '10.1.0.156',
  cluster_address => '10.0.0.56'
}
"
  end

  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/lib/concat',
      :processorcount => 8,
      :hostname       => 'dummy-host'
    }
  end

  describe 'when the device is empty' do

    it { should include_class('ceph::osd') }
    it { should include_class('ceph::conf') }

    it { should contain_exec('mktable_gpt_device').with(
      'command'   => 'parted -a optimal --script /dev/device mktable gpt',
      'unless'    => "parted --script /dev/device print|grep -sq 'Partition Table: gpt'",
      'logoutput' => 'true',
      'require'   => 'Package[parted]'
    ) }

    it { should contain_exec('mkpart_device').with(
      'command'   => 'parted -a optimal -s /dev/device mkpart ceph 0% 100%',
      'unless'    => "parted /dev/device print | egrep '^ 1.*ceph$'",
      'logoutput' => 'true',
      'require'   => ['Package[parted]', 'Exec[mktable_gpt_device]']
    ) }

    it { should contain_exec('mkfs_device').with(
      'command'   => 'sleep 5 && mkfs.xfs -f -d agcount=8 -l size=1024m -n size=64k /dev/device1',
      'unless'    => 'xfs_admin -l /dev/device1',
      'logoutput' => 'true',
      'require'   => ['Package[xfsprogs]', 'Exec[mkpart_device]']
    ) }

  end

  describe 'when the partition is created' do
    let :pre_condition do
    "class { 'ceph::conf': fsid => '12345' }
class { 'ceph::osd':
  public_address  => '10.1.0.156',
  cluster_address => '10.0.0.56'
}
ceph::key { 'admin':
  secret => 'dummy'
}
"
    end
    let :facts do
      {
        :concat_basedir     => '/var/lib/puppet/lib/concat',
        :blkid_uuid_device1 => 'dummy-uuid-1234',
        :hostname           => 'dummy-host'
      }
    end

    it { should contain_exec('ceph_osd_create_device').with(
      'command' => 'ceph osd create dummy-uuid-1234',
      'unless'  => 'ceph osd dump | grep -sq dummy-uuid-1234'
    ) }

    describe 'when the osd is created' do
      let :facts do
        {
          :concat_basedir      => '/var/lib/puppet/lib/concat',
          :blkid_uuid_device1  => 'dummy-uuid-1234',
          :ceph_osd_id_device1 => '56',
          :hostname            => 'dummy-host'
        }
      end

      it { should contain_ceph__conf__osd('56').with(
        'device'       => '/dev/device1',
        'public_addr'  => '10.1.0.156',
        'cluster_addr' => '10.0.0.56'
      ) }

      it { should contain_file('/var/lib/ceph/osd/osd.56').with(
        'ensure' => 'directory'
      ) }

      it { should contain_mount('/var/lib/ceph/osd/osd.56').with(
        'ensure'  => 'present',
        'device'  => '/dev/device1',
        'fstype'  => 'xfs',
        'options' => 'rw,noatime,inode64,noauto',
        'pass'    => 0,
        'require' => ['Exec[mkfs_device]', 'File[/var/lib/ceph/osd/osd.56]']
      ) }

      it { should contain_exec('ceph-osd-mkfs-56').with(
        'command' => 'mount /var/lib/ceph/osd/osd.56 && ceph-osd -c /etc/ceph/ceph.conf -i 56 --mkfs --mkkey --osd-uuid dummy-uuid-1234
',
        'unless'  => "ceph auth list | egrep '^osd.56$'",
        'creates' => '/var/lib/ceph/osd/osd.56/keyring',
        'require' => ['Mount[/var/lib/ceph/osd/osd.56]', 'Concat[/etc/ceph/ceph.conf]']
      ) }

      it { should contain_exec('ceph-osd-register-56').with(
        'command' => "ceph auth add osd.56 osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/osd.56/keyring",
        'unless'  => "ceph auth list | egrep '^osd.56$'",
        'require' => 'Exec[ceph-osd-mkfs-56]'
      ) }

    end

  end

end

describe 'ceph::osd::device' do

  let :title do
    '/dev/disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0'
  end

  let :pre_condition do
    "class { 'ceph::conf': fsid => '12345', osd_crush_location => 'room=dummy-room' }
class { 'ceph::osd':
  public_address  => '10.1.0.156',
  cluster_address => '10.0.0.56'
}
"
  end

  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/lib/concat',
      :processorcount => 8,
      :hostname       => 'dummy-host'
    }
  end

  describe 'when the device is empty' do

    it { should include_class('ceph::osd') }
    it { should include_class('ceph::conf') }

    it { should contain_exec('mktable_gpt_pci-0000:02:00.0-sas-0x500015554964d213-lun-0').with(
      'command' => 'parted -a optimal --script /dev/disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0 mktable gpt',
      'unless'  => "parted --script /dev/disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0 print|grep -sq 'Partition Table: gpt'",
      'require' => 'Package[parted]'
    ) }

    it { should contain_exec('mkpart_pci-0000:02:00.0-sas-0x500015554964d213-lun-0').with(
      'command' => 'parted -a optimal -s /dev/disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0 mkpart ceph 0% 100%',
      'unless'  => "parted /dev/disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0 print | egrep '^ 1.*ceph$'",
      'require' => ['Package[parted]', 'Exec[mktable_gpt_pci-0000:02:00.0-sas-0x500015554964d213-lun-0]']
    ) }

    it { should contain_exec('mkfs_pci-0000:02:00.0-sas-0x500015554964d213-lun-0').with(
      'command' => 'sleep 5 && mkfs.xfs -f -d agcount=8 -l size=1024m -n size=64k /dev/disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0-part1',
      'unless'  => 'xfs_admin -l /dev/disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0-part1',
      'require' => ['Package[xfsprogs]', 'Exec[mkpart_pci-0000:02:00.0-sas-0x500015554964d213-lun-0]']
    ) }

  end

  describe 'when the partition is created' do
    let :pre_condition do
    "class { 'ceph::conf': fsid => '12345' }
class { 'ceph::osd':
  public_address  => '10.1.0.156',
  cluster_address => '10.0.0.56'
}
ceph::key { 'admin':
  secret => 'dummy'
}
"
    end
    let :facts do
      {
        :concat_basedir     => '/var/lib/puppet/lib/concat',
        :'blkid_uuid_disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0-part1' => 'dummy-uuid-1234',
        :hostname           => 'dummy-host'
      }
    end

    it { should contain_exec('ceph_osd_create_pci-0000:02:00.0-sas-0x500015554964d213-lun-0').with(
      'command' => 'ceph osd create dummy-uuid-1234',
      'unless'  => 'ceph osd dump | grep -sq dummy-uuid-1234'
    ) }

    describe 'when the osd is created' do
      let :facts do
        {
          :concat_basedir      => '/var/lib/puppet/lib/concat',
          :'blkid_uuid_disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0-part1'  => 'dummy-uuid-1234',
          :'ceph_osd_id_disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0-part1' => '56',
          :hostname            => 'dummy-host'
        }
      end

      it { should contain_ceph__conf__osd('56').with(
        'device'       => '/dev/disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0-part1',
        'public_addr'  => '10.1.0.156',
        'cluster_addr' => '10.0.0.56'
      ) }

      it { should contain_file('/var/lib/ceph/osd/osd.56').with(
        'ensure' => 'directory'
      ) }

      it { should contain_mount('/var/lib/ceph/osd/osd.56').with(
        'ensure'  => 'present',
        'device'  => '/dev/disk/by-path/pci-0000:02:00.0-sas-0x500015554964d213-lun-0-part1',
        'fstype'  => 'xfs',
        'options' => 'rw,noatime,inode64,noauto',
        'pass'    => 0,
        'require' => ['Exec[mkfs_pci-0000:02:00.0-sas-0x500015554964d213-lun-0]', 'File[/var/lib/ceph/osd/osd.56]']
      ) }

      it { should contain_exec('ceph-osd-mkfs-56').with(
        'command' => 'mount /var/lib/ceph/osd/osd.56 && ceph-osd -c /etc/ceph/ceph.conf -i 56 --mkfs --mkkey --osd-uuid dummy-uuid-1234
',
        'unless'  => "ceph auth list | egrep '^osd.56$'",
        'creates' => '/var/lib/ceph/osd/osd.56/keyring',
        'require' => ['Mount[/var/lib/ceph/osd/osd.56]', 'Concat[/etc/ceph/ceph.conf]']
      ) }

      it { should contain_exec('ceph-osd-register-56').with(
        'command' => "ceph auth add osd.56 osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/osd.56/keyring",
        'unless'  => "ceph auth list | egrep '^osd.56$'",
        'require' => 'Exec[ceph-osd-mkfs-56]'
      ) }

    end

  end

end
