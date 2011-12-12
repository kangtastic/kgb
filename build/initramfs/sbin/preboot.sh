#!/bin/sh
# Preboot script - runs before zygote

auto_install()
# source, dest, chown, chmod
{
if ! cmp /res/src/$1 $2; then
	mv $2 $2-`date '+%Y-%m-%d_%H-%M-%S'`
	cp /res/src/$1 $2
	chown $3 $2
	chmod $4 $2
fi
}

# Remount rootfs & system rw
mount -t rootfs -o rw,remount rootfs /
mount -o rw,remount /system /system

# Create /etc/init.d as necessary
/bin/mkdir -p /system/etc/init.d

# Install bootanimation
if [ -f /data/local/bootanimation.zip ] || [ -f /system/media/bootanimation.zip ] || [ -f /system/media/sanim.zip ]; then
	auto_install bootanimation /system/bin/bootanimation 0.2000 755
fi

# Install bash and supporting files
if ! cmp /res/src/bash /system/xbin/bash; then
	auto_install bash /system/xbin/bash 0.0 755
	auto_install libncurses.so /system/lib/libncurses.so 0.0 644
	/bin/rm -rf /system/etc/bash
	/bin/cp -rf /res/src/bash_files /system/etc/bash
	/bin/rm -rf /system/etc/terminfo
	/bin/cp -rf /res/src/terminfo /system/etc/terminfo
fi

# Install nano and supporting files
if ! cmp /res/src/nano /system/xbin/nano; then
	auto_install nano /system/xbin/nano 0.0 755
	auto_install libncurses.so /system/lib/libncurses.so 0.0 644
	/bin/rm -rf /system/etc/nano
	/bin/cp -rf /res/src/nano_files /system/etc/nano
	/bin/rm -rf /system/etc/terminfo
	/bin/cp -rf /res/src/terminfo /system/etc/terminfo
fi	

# The ramdisk's busybox does not have grep nor ls so check for a system busybox

# Create resolv.conf, add multicasted Verizon and Google DNS servers as necessary
if [ -x /system/xbin/busybox ]; then
	RC=/system/etc/resolv.conf

	[ ! -f $RC ] || ( > $RC && chown 0.0 $RC && chmod 644 $RC )

	grep "4.2.2.2" $RC || echo "nameserver 4.2.2.2" >> $RC
	grep "4.2.2.4" $RC || echo "nameserver 4.2.2.4" >> $RC
	grep "8.8.8.8" $RC || echo "nameserver 8.8.8.8" >> $RC
	grep "8.8.4.4" $RC || echo "nameserver 8.8.4.4" >> $RC

# Add a little helper named ll to call "/system/xbin/busybox ls -al $*"
	if [ ! "$(cat /system/xbin/ll)" = "/system/xbin/busybox ls -al \$*" ]; then
		echo "/system/xbin/busybox ls -al \$*" > /system/xbin/ll
		chmod 755 /system/xbin/ll
	fi

fi

# Remount system ro,noatime
mount -o ro,remount,noatime /system /system

# Set kernel vm parameters
# Move these here so that init.d scripts may modify these values later
PSVM=/proc/sys/vm
echo 100 > $PSVM/vfs_cache_pressure
echo 20 > $PSVM/dirty_ratio
echo 5 > $PSVM/dirty_background_ratio
echo 200 > $PSVM/dirty_expire_centisecs
echo 500 > $PSVM/dirty_writeback_centisecs
# According to my very unscientific tests this is best left at default
# echo 256 > $PSVM/lowmem_reserve_ratio
echo 4 > $PSVM/min_free_order_shift
# Same with this one, although there's much less evidence in this case
# echo 4096 > $PSVM/min_free_kbytes
echo 3 > $PSVM/page-cluster
echo 60 > $PSVM/swappiness
