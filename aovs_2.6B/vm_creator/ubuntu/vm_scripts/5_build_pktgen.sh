#!/bin/bash

export DPDK_BASE_DIR=/root
export DPDK_VERSION=dpdk-17.05
export DPDK_TARGET=x86_64-native-linuxapp-gcc
export DPDK_BUILD=$DPDK_BASE_DIR/$DPDK_VERSION/$DPDK_TARGET
export PKTGEN=pktgen-3.4.1

echo "Cleaning.."
if [ -d "$DPDK_BASE_DIR/$PKTGEN" ]; then
  rm -rf $DPDK_BASE_DIR/$PKTGEN
fi

if [ ! -e "$DPDK_BASE_DIR/$PKTGEN.tar.gz" ]; then
  echo "Downloading.."
  wget http://dpdk.org/browse/apps/pktgen-dpdk/snapshot/$PKTGEN.tar.gz --directory-prefix=$DPDK_BASE_DIR
fi

echo "Extracting.."
tar xf $DPDK_BASE_DIR/$PKTGEN.tar.gz -C $DPDK_BASE_DIR
cd $DPDK_BASE_DIR/$PKTGEN
sed 's/DEFAULT_PKT_BURST       = 32/DEFAULT_PKT_BURST       = 64/g' -i ./app/pktgen-constants.h
sed '/DEFAULT_RX_DESC         =/d' -i ./app/pktgen-constants.h
sed '/DEFAULT_TX_DESC         =/d' -i ./app/pktgen-constants.h
sed -i "/DEFAULT_PKT_BURST/aDEFAULT_RX_DESC = 512," ./app/pktgen-constants.h
sed -i "/DEFAULT_PKT_BURST/aDEFAULT_TX_DESC = 1024," ./app/pktgen-constants.h

#Change MAX_MBUFS_PER_PORT * 8 to 32 for more flows per port
sed -i '/.*number of buffers to support per port.*/c\\tMAX_MBUFS_PER_PORT\t= (DEFAULT_TX_DESC * 32),/* number of buffers to support per port */' /root/$PKTGEN/app/pktgen-constants.h

sleep 1

make RTE_SDK=$DPDK_BASE_DIR/$DPDK_VERSION RTE_TARGET=$DPDK_TARGET

rm -f /root/dpdk-pktgen
ln -s $DPDK_BASE_DIR/$PKTGEN/app/x86_64-native-linuxapp-gcc/pktgen /root/$PKTGEN/dpdk-pktgen

cat <<EOF > /etc/dpdk-pktgen-settings.sh
export DPDK_PKTGEN_DIR=$srcdir/$PKTGEN
export DPDK_PKTGEN_EXEC=$srcdir/$PKTGEN/app/app/$RTE_TARGET/pktgen
EOF

cat <<EOF > /etc/dpdk-pktgen-settings.sh
export DPDK_PKTGEN_DIR=$srcdir/$PKTGEN
export DPDK_PKTGEN_EXEC=$srcdir/$PKTGEN/app/app/$RTE_TARGET/pktgen
EOF

exit 0
