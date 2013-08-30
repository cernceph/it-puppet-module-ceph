#
# disksbypath.rb
#
# author: daniel.vanderster@cern.ch
#

require 'facter'

if Facter.value(:kernel) == 'Linux' and File.exists?('/dev/disk/by-path')
  disksbypath = []

  Facter::Util::Resolution.exec('ls /dev/disk/by-path/ 2> /dev/null').each_line do |line|
    line.strip!
    next if line.empty? or line.match(/-part/)
    disksbypath << line
  end

  Facter.add('disksbypath') do
    confine :kernel => :linux
    setcode { disksbypath.sort.uniq.join(',') }
  end
end
