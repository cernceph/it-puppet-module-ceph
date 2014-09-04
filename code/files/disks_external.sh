#!/bin/bash
#
# disks_external.sh
#
# Is an external fact which creates a fact disks_external which is a 
# list of externally attached disks.
#

echo -n disks_external=
for ENCLO in `lsscsi -g | grep enclos | sed -r 's/^\[([0-9]+):.*$/\1/'`
do
  lsscsi -t $ENCLO | grep /dev/sd | awk '{print $4}' | sed 's^/dev/^^'
done | xargs echo | sed 's/ /,/g'
