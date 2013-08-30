require 'spec_helper'

describe "ceph::client" do

  let :facts do
    { :concat_basedir => "/var/lib/puppet/concat" }
  end

  let :params do
    { :fsid => 'qwertyuiop' }
  end

  it { should include_class('ceph::conf') }
  it { should include_class('ceph::params') }
  it { should include_class('ceph::conf::client') }

end
