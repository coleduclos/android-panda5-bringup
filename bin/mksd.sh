#!/bin/sh

. bin/envsetup.sh

function abort() {
	echo "Operation \"$1\" failed. For more details, log is $L"
	exit $2
}
	
DEV=/dev/mmcblk0
T=/tmp/$$
L=/tmp/$$.log

if [  "x`id -u`" != "x0" ]; then
   echo "Running with sudo..."
   sudo sh $0 $*
   echo "Completed"
   exit 0
fi

while true; do
   echo "Checking device mount state..."
   m=`mount | grep $DEV | wc -l`
   if [ "x$m" == "x0" ]; then
	break
   fi
   echo "Unmounting ($m times mounted)"
   umount $DEV*
done

echo "Partitioning..."
parted --script --machine $DEV mklabel msdos >> $L
[ $? -eq 0 ] || abort "Delete all partitions"
echo -e "n\np\n1\n\n+128M\nw\n" | fdisk $DEV >> $L
[ $? -eq 0 ] || abort "create boot partition"
echo -e "n\ne\n2\n\n\nw\n" | fdisk $DEV >> $L
# [ $? -eq 0 ] || abort "create ext partition"
echo -e "n\nl\n\n+512M\nw\n" | fdisk $DEV >> $L
# [ $? -eq 0 ] || abort "create logical partition 'root'"
echo -e "n\nl\n\n+512M\nw\n" | fdisk $DEV >> $L
# [ $? -eq 0 ] || abort "create logical partition 'root'"
echo -e "n\nl\n\n+512M\nw\n" | fdisk $DEV >> $L
# [ $? -eq 0 ] || abort "create logical partition 'system'"
echo -e "n\nl\n\n+512M\nw\n" | fdisk $DEV >> $L
# [ $? -eq 0 ] || abort "create logical partition 'data'"
echo -e "n\nl\n\n+512M\nw\n" | fdisk $DEV >> $L
# [ $? -eq 0 ] || abort "create logical partition 'cache'"
echo -e "t\n1\n6\na\n1\nw\n" | fdisk $DEV >> $L
# [ $? -eq 0 ] || abort "create logical partition 'factory'"
echo "Partitioning complete."

echo "Formatting..."
mkfs.vfat -F 16 ${DEV}p1 -n boot >> $L
[ $? -eq 0 ] || abort "Formatting boot"
	
mkfs.ext4 ${DEV}p5 -L root >> $L
[ $? -eq 0 ] || abort "Formatting root"

mkfs.ext4 ${DEV}p6 -L system >> $L
[ $? -eq 0 ] || abort "Formatting system"

mkfs.ext4 ${DEV}p7 -L data >> $L
[ $? -eq 0 ] || abort "Formatting data"

mkfs.ext4 ${DEV}p8 -L cache >> $L
[ $? -eq 0 ] || abort "Formatting cache"

mkfs.ext4 ${DEV}p9 -L factory >> $L
[ $? -eq 0 ] || abort "Formatting factory"

echo "Formatting complete"

echo "Copying files..."
mkdir -p $T

mount ${DEV}p1 $T
pushd $PREBUILT
mkimage -A arm -T script -O linux -C none -a 0 -e 0 -n "boot.scr" -d boot.scr.txt boot.scr >> $L
[ $? -eq 0 ] || abort "mkimage of boot.scr"

popd
for a in MLO u-boot.img uImage omap5-uevm.dtb boot.scr; do
   cp -v $PREBUILT/$a $T >> $L
   [ $? -eq 0 ] || abort "Copying of $PREBUILT/$a"
done
umount $T
echo "Boot partition ready"

mkdir -p $T
mount ${DEV}p5 $T
cp -av $DISCIMAGE/root/* $T >> $L
cp $T/init.omap5sevmboard.rc $T/init.omap5430evmboard.rc
rm $T/init.omap5sevmboard.rc*
[ $? -eq 0 ] || abort "Copying of root partition"
umount $T
echo "Root partition ready"

# some preparations...
# copy SGX binaries...
# cp -va $DISCIMAGE/system/* $DOUT/system
# cp -va $DISCIMAGE/data/* $DOUT/data
# kernel modules
mkdir -p $DISCIMAGE/system/vendor/lib/modules
cp -v omaplfb-wip/omaplfb_linux/omaplfb_sgx544_105.ko $DISCIMAGE/system/vendor/lib/modules >> $L
cp -v $DISCIMAGE/target/kbuild/pvrsrvkm_sgx544_105.ko $DISCIMAGE/system/vendor/lib/modules >> $L

mkdir -p $T
mount ${DEV}p6 $T
cp -a $DISCIMAGE/system/* $T >> $L
[ $? -eq 0 ] || abort "Copying of system partition"

# then some removals
rm $T/lib/hw/camera*
umount $T
echo "System partition ready"

mkdir -p $T
mount ${DEV}p7 $T
cp -a $DISCIMAGE/data/* $T
[ $? -eq 0 ] || abort "Copying of data partition"
umount $T
echo "Data partition ready"

echo "Done at `date`"

