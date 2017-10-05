#!/bin/bash

export DPDK_BASE_DIR=/root
PKTGEN_VERSION=$(readlink /root/dpdk-pktgen | awk -F '/' '{print $3}')
export PKTGEN=$DPDK_BASE_DIR/$PKTGEN_VERSION
cd $PKTGEN

CPU_COUNT=$(cat /proc/cpuinfo | grep processor | wc -l)
SRIOV_LIST=$(lspci -d 19ee: | awk '{print $1}')
XVIO_LIST=$(lspci | awk '/Red Hat, Inc Virtio network device/ {print $1}' | tail -n +2)
NETRONOME_VF_LIST="$SRIOV_LIST $XVIO_LIST"
memory="--socket-mem 1024"
lcores="-l 0-$((CPU_COUNT-1))"

# whitelist
whitelist=""
for netronome_vf in ${NETRONOME_VF_LIST[@]};
do
  echo "netronome_vf: $netronome_vf"
  whitelist="$whitelist $netronome_vf"
done

# cpumapping
cpu_counter=0
port_counter=0
mapping=""
for netronome_vf in ${NETRONOME_VF_LIST[@]};
do
  echo "netronome_vf: $netronome_vf"
  mapping="${mapping}-m "
  cpu_counter=$((cpu_counter+1))
  echo "cpu_counter: $cpu_counter"
  mapping="${mapping}$cpu_counter.${port_counter} "
  port_counter=$((port_counter+1))
done

echo "whitelist: $whitelist"
echo "mapping: $mapping"

/root/dpdk-pktgen $lcores --proc-type auto $memory -n 4 --log-level=7 $whitelist --file-prefix=dpdk0_ -- $mapping -N -f unidirectional_transmitter.lua

reset
