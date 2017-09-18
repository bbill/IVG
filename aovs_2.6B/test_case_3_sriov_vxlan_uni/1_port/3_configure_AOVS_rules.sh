#!/bin/bash

BONDBR_DEST_IP=$1 
BONDBR_SRC_IP=$2

if [ -z "$1" ] && [ -z "$2" ]; then
    echo "ERROR: Not enough parameters where passed to this script"
    echo "Example: ./3_configure_AOVS_rules.sh 10.10.10.1 10.10.10.2"
    exit -1
else
    BONDBR_DEST_IP=$1 
    BONDBR_SRC_IP=$2
fi    

BRIDGE=br0

# Delete all bridges
for br in $(ovs-vsctl list-br);
do
  ovs-vsctl --if-exists del-br $br
done

#Add PF to br0
ovs-vsctl add-port $BRIDGE nfp_p0 -- set interface nfp_p0 ofport_request=1

#Add VF's to br0 
ovs-vsctl add-port $BRIDGE nfp_v0.10 -- set interface nfp_v0.10 ofport_request=10
ovs-vsctl add-port $BRIDGE nfp_v0.11 -- set interface nfp_v0.11 ofport_request=11

ifconfig $BRIDGE_BOND $BONDBR_SRC_IP

ovs-vsctl add-port br0 vxlan01 -- set interface vxlan01 type=vxlan options:remote_ip=$BONDBR_DEST_IP

ovs-ofctl show $BRIDGE
ovs-ofctl dump-flows $BRIDGE


ovs-vsctl set Open_vSwitch . other_config:max-idle=300000
ovs-vsctl set Open_vSwitch . other_config:flow-limit=1000000
ovs-appctl upcall/set-flow-limit 1000000

exit 0

