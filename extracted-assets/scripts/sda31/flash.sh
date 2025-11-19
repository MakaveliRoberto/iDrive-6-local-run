#!/bin/ksh
# set -x
# flash script for FPGA on NBT omap platform used by ESys Flash

VERSION=V1.0.0
echo "$0: $VERSION"
echo "Make bootloader executable sda31"
echo "Make bootloader executable sda31 ..." > /dev/console
chmod -R a+x /net/*omap/fs/sda32
echo "Make bootloader executable sda32"
chmod -R a+x /net/*omap/fs/sda31/
echo "done Make bootloader executable" > /dev/console
rm -f /net/*-omap/fs/sda1/opt/sys/persistence/early/pers_NBTCarHUTwoSignature
rm -f /net/*-omap/fs/sda1/opt/sys/persistence/early/pers_LinkManagerHULinkManager
echo "done Delete Signature status of Linkmanager and Signature component" > /dev/console