#!/bin/bash

#Check if VM name is passed
if [ -z "$1" ]; then
   echo "ERROR: No VM name was passed to this script."
   echo "Example: ./4_guest_xml_configure.sh <vm_name>"
   exit -1
   else
   VM_NAME=$1
fi

s_bus=$(ethtool -i nfp_v0.42 | grep bus-info | awk '{print $5}' | awk -F ':' '{print $2}')

# Remove vhostuser interface
EDITOR='sed -i "/<interface type=.vhostuser.>/,/<\/interface>/d"' virsh edit $VM_NAME
EDITOR='sed -i "/<hostdev mode=.subsystem. type=.pci./,/<\/hostdev>/d"' virsh edit $VM_NAME

# Add vhostuser interfaces
# nfp_v0.41 --> 0000:81:0d.1
# nfp_v0.42 --> 0000:81:0d.2

cat > /tmp/interface << EOL
      <interface type='hostdev' managed='yes'>
          <source>
              <address type='pci' domain='0x0000' bus='0x${s_bus}' slot='0x0d' function='0x01'/>
          </source>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x0a' function='0x00'/>
      </interface>
EOL
  virsh attach-device $VM_NAME /tmp/interface --config

sleep 1
echo "Device attached"

cat > /tmp/interface << EOL
      <interface type='hostdev' managed='yes'>
          <source>
              <address type='pci' domain='0x0000' bus='0x${s_bus}' slot='0x0d' function='0x02'/>
          </source>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x0b' function='0x00'/>
      </interface>
EOL
  virsh attach-device $VM_NAME /tmp/interface --config

echo "Device attached"

exit 0
