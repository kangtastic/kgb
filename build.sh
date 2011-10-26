#!/bin/bash
###############
# DEFINITIONS #
###############

# Instantaneous date/time
DATE=$(date +%m%d)
TIME=$(date +%H%M)

# Kernel version tag
KERNEL_VERSION="TKSGB Kernel for Samsung SCH-I500. Buildcode: $DATE.$TIME"

# Toolchain paths
TOOLCHAIN=/home/vb/toolchain/arm-2009q3/bin
TOOLCHAIN_PREFIX=arm-none-linux-gnueabi-
STRIP=${TOOLCHAIN}/${TOOLCHAIN_PREFIX}strip

# Other paths
ROOTDIR=`pwd`
BUILDDIR=$ROOTDIR/build
WORKDIR=$BUILDDIR/bin
OUTDIR=$BUILDDIR/out

KERNEL_IMAGE=$ROOTDIR/arch/arm/boot/zImage

####################
# HELPER FUNCTIONS #
####################

echo_msg()
# $1: Message to print to output
{
echo ""
echo "*** $1 ***"
echo ""
}

probe_rmdir()
# $1: Directory path
{
if [ -d "$1" ]; then
	rm -rf $1
fi
}

probe_mkdir()
# $1: Directory path
{
if [ ! -d "$1" ]; then
	mkdir $1
fi
}

makezip()
# $1: Name of output file without extension
# Creates $OUTDIR/$1.zip
{
echo "Creating: $OUTDIR/$1.zip"
pushd $WORKDIR/update-zip/META-INF/com/google/android > /dev/null
sed s_"\$DATE"_"$DATE"_ < updater-script > updater-script.tmp
mv -f updater-script.tmp updater-script
popd > /dev/null
pushd $WORKDIR/update-zip
zip -r -q "$1.zip" .
mv "$1.zip" $OUTDIR/
popd > /dev/null
}

makeodin()
# $1: Name of output file without extension
# Creates $OUTDIR/$1.tar.md5
{
echo "Creating: $OUTDIR/$1.tar.md5"
pushd $WORKDIR > /dev/null
tar -H ustar -cf "$1.tar" zImage
md5sum -t "$1.tar" >> "$1.tar"
mv "$1.tar" "$OUTDIR/$1.tar.md5"
popd
}

####################
# SCRIPT MAIN BODY #
####################

echo_msg "BUILD START: $KERNEL_VERSION"

# Clean kernel and old files
echo_msg "CLEANING FILES FROM PREVIOUS BUILD"
probe_rmdir $WORKDIR
probe_rmdir $OUTDIR
make CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX clean mrproper

# Generate config, build & copy modules, write kernel version tag
echo_msg "CONFIGURING KERNEL AND GENERATING INITRAMFS"
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX tksgb_defconfig

make ARCH=arm CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX modules
probe_mkdir $WORKDIR
cp -r $BUILDDIR/initramfs $WORKDIR/
for line in `cat modules.order`
do
	echo ${line:7}
	cp ${line:7} $WORKDIR/initramfs/lib/modules/
	$STRIP --strip-debug $WORKDIR/initramfs/lib/modules/$(basename $line)
done

# Replace/remove some modules
cp -f $BUILDDIR/initramfs-stock/lib/modules/dpram_atlas.ko $WORKDIR/initramfs/lib/modules/dpram_atlas.ko
cp -f $BUILDDIR/initramfs-stock/lib/modules/dpram_recovery.ko $WORKDIR/initramfs/lib/modules/dpram_recovery.ko
rm $WORKDIR/initramfs/lib/modules/hotspot_event_monitoring.ko

echo $KERNEL_VERSION > $WORKDIR/initramfs/kernel_version

# Make kernel
echo_msg "STARTING MAIN KERNEL BUILD"
make -j `expr $(grep processor /proc/cpuinfo | wc -l) + 1` \
	ARCH=arm CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX

# Create packages
echo_msg "CREATING CWM AND ODIN PACKAGES"
cp -r $BUILDDIR/update-zip $WORKDIR/

cp $KERNEL_IMAGE $WORKDIR/update-zip/kernel_update/zImage
cp $KERNEL_IMAGE $WORKDIR/zImage

probe_mkdir $OUTDIR
makezip "TKSGB-I500-$DATE.$TIME"
makeodin "TKSGB-I500-$DATE.$TIME"
makeodin "TKSGB-I500-$DATE"

echo_msg "BUILD COMPLETE: $KERNEL_VERSION"
exit
