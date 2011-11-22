#!/bin/bash
# Instantaneous date/time
DATE=$(date +%m%d)
TIME=$(date +%H%M)
START_TIME_SEC=$(date +%s)

# Using an uninitialized variable? Executed command throws an error? Quit
set -u
set -e

###############
# DEFINITIONS #
###############
# Toolchain paths
TOOLCHAIN=/home/vb/toolchain/arm-2011.03/bin
TOOLCHAIN_PREFIX=arm-none-linux-gnueabi-
STRIP=${TOOLCHAIN}/${TOOLCHAIN_PREFIX}strip

# Kernel version tag
KERNEL_VERSION="TKSGB Kernel for Samsung SCH-I500. Buildcode: $DATE.$TIME"

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
echo "
*** $1 ***
"
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
mv -f "$1.zip" $OUTDIR/
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
mv -f "$1.tar" "$OUTDIR/$1.tar.md5"
popd
}

####################
# SCRIPT MAIN BODY #
####################

echo "Build script run on $(date -R)"

echo_msg "BUILD START: $KERNEL_VERSION"

# Clean kernel and old files
echo_msg "CLEANING FILES FROM PREVIOUS BUILD"
rm -rf $WORKDIR
rm -rf $OUTDIR
make CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX clean mrproper

# Generate config
echo_msg "CONFIGURING KERNEL"
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX tksgb_defconfig

# Generate initramfs
echo_msg "GENERATING INITRAMFS"
mkdir -p $WORKDIR
cp -rf $BUILDDIR/initramfs $WORKDIR/

# Make modules, strip and copy to generated initramfs
echo_msg "BUILDING MODULES"
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX modules
for line in `cat modules.order`
do
	echo ${line:7}
	cp -f ${line:7} $WORKDIR/initramfs/lib/modules/
	$STRIP --strip-debug $WORKDIR/initramfs/lib/modules/$(basename $line)
done

# Replace source-built OneNAND driver with stock modules from EH03
cp -f $BUILDDIR/initramfs-EH03/lib/modules/dpram_atlas.ko $WORKDIR/initramfs/lib/modules/dpram_atlas.ko
cp -f $BUILDDIR/initramfs-EH03/lib/modules/dpram_recovery.ko $WORKDIR/initramfs/lib/modules/dpram_recovery.ko

# Remove unwanted initramfs files
rm -f $WORKDIR/initramfs/lib/modules/hotspot_event_monitoring.ko

# Write kernel version tag into initramfs root
echo $KERNEL_VERSION > $WORKDIR/initramfs/kernel_version

# Make kernel
echo_msg "BUILDING KERNEL"
make -j `expr $(grep processor /proc/cpuinfo | wc -l) + 1` \
	ARCH=arm CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX

# Create packages
echo_msg "CREATING CWM AND ODIN PACKAGES"
cp -rf $BUILDDIR/update-zip $WORKDIR/

cp -f $KERNEL_IMAGE $WORKDIR/update-zip/kernel_update/zImage
cp -f $KERNEL_IMAGE $WORKDIR/zImage

mkdir -p $OUTDIR
makezip "TKSGB-I500-$DATE.$TIME"
makeodin "TKSGB-I500-$DATE.$TIME"

# If you are not me, this ain't here kthx >;]
if [ -d /mnt/vbs ]; then
	cp -f "$OUTDIR/TKSGB-I500-$DATE.$TIME.tar.md5" /mnt/vbs/
	makeodin "TKSGB-I500-$DATE"
fi

#######
# END #
#######

echo_msg "BUILD COMPLETE: $KERNEL_VERSION"

END_TIME_SEC=$(date +%s)
TIME_DIFF=$(($END_TIME_SEC - $START_TIME_SEC))

echo "Build script exiting on $(date -R). Elapsed time: $(($TIME_DIFF / 60))m$(($TIME_DIFF % 60))s"

exit
