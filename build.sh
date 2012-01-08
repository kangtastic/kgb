#!/bin/bash
# Instantaneous date/time
DATE=$(date +%m%d)
TIME=$(date +%H%M)
START_TIME_SEC=$(date +%s)

# Using an uninitialized variable? Executed command throws an error? Quit
set -u
set -e

############################
# VARIABLE INITIALIZATIONS #
############################
# Toolchain paths
TOOLCHAIN=/home/vb/toolchain/arm-2011.03/bin
TOOLCHAIN_PREFIX=arm-none-linux-gnueabi-
STRIP=${TOOLCHAIN}/${TOOLCHAIN_PREFIX}strip

# Other paths
ROOTDIR=`pwd`
BUILDDIR=${ROOTDIR}/build
WORKDIR=${BUILDDIR}/bin
OUTDIR=${BUILDDIR}/out

KERNEL_IMAGE=${ROOTDIR}/arch/arm/boot/zImage

# More initializations (they need to go somewhere because of set -u)
KERNEL_VERSION=""
TARGET=""
DEFCONFIG=""

####################
# HELPER FUNCTIONS #
####################
echo_msg()
# $1: Message, with some formatting, to print to output
{
echo "
*** $1 ***
"
}
help_msg()
# Print usage information and exit
# $1: exit code (0 or 1)
{
echo 'Usage: ./build.sh -t TARGET [-bh]

	-t TARGET	mandatory argument to specify a ROM target
			valid values of TARGET are "EH03", "EI20", and "EH09"
	-h		displays this help message and exit

Example: ./build.sh -t EH03
	 ./build.sh -t EH09 -b'
exit $1
}
makezip()
# $1: Name of output file without extension
# Creates $OUTDIR/$1.zip
{
echo "Creating: $OUTDIR/$1.zip"
pushd $WORKDIR/update-zip/META-INF/com/google/android > /dev/null
sed s_"\$CODE"_"$KERNEL_VERSION"_ < updater-script > updater-script.tmp
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
echo "Build script running on $(date -R)"

# Parse the command line
[ $# -eq 0 ] && echo "./build.sh: no arguments to script" >&2 && help_msg 1
while getopts t:bh OPT; do
	case "$OPT" in
		t)
			TARGET=$OPTARG
			;;
		h)
			help_msg 0
			;;
		\?)
			help_msg 1
			;;
	esac
done
# Check for valid target while generating defconfig filename and kernel version string
if [ "$TARGET" = "EH03" ]; then
	DEFCONFIG="kgb"
elif [ "$TARGET" = "EI20" ]; then
	DEFCONFIG="kgb_ei20"
elif [ "$TARGET" = "EH09" ]; then
	DEFCONFIG="kgb_eh09"
else
	[ $TARGET = "" ] && TARGET="not specified"
	echo "./build.sh: invalid target: $TARGET" >&2 && help_msg 1
fi

KERNEL_VERSION="KGB-${TARGET}-${DATE}.${TIME}"
DEFCONFIG="${DEFCONFIG}_defconfig"

# We're starting!
echo_msg "BUILD START: $KERNEL_VERSION"

# Clean kernel and old files
echo_msg "CLEANING FILES FROM PREVIOUS BUILD"
rm -rf $WORKDIR
rm -rf $OUTDIR
make CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX clean mrproper

# Generate config
echo_msg "CONFIGURING KERNEL"
make ARCH=arm CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX $DEFCONFIG

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
makezip $KERNEL_VERSION
makeodin $KERNEL_VERSION

# If you are not me, this ain't here kthx >;]
if [ -d /mnt/vbs ]; then
	cp -f "${OUTDIR}/${KERNEL_VERSION}.tar.md5" /mnt/vbs/
	cp -f "${OUTDIR}/${KERNEL_VERSION}.zip" /mnt/vbs/
	makeodin "KGB-${TARGET}-${DATE}"
fi

#######
# END #
#######

echo_msg "BUILD COMPLETE: $KERNEL_VERSION"

END_TIME_SEC=$(date +%s)
TIME_DIFF=$(($END_TIME_SEC - $START_TIME_SEC))

echo "Build script exiting on $(date -R). Elapsed time: $(($TIME_DIFF / 60))m$(($TIME_DIFF % 60))s"

exit
