#!/bin/sh
# Preboot script - runs before zygote

# Remount rootfs rw, system rw and noatime
mount -t rootfs -o rw,remount rootfs /
mount -o rw,remount,noatime /system /system

# Install bootanimation binary as necessary
REFBANIM=/res/lib/bootanimation
SYSBANIM=/system/bin/bootanimation
if ! cmp $REFBANIM $SYSBANIM; then
	cat $REFBANIM > $SYSBANIM
	chown 0.2000 $SYSBANIM
	chmod 755 $SYSBANIM
fi

# Create /etc/init.d as necessary
/bin/mkdir -p /system/etc/init.d

# Create resolv.conf, add multicasted Verizon and Google DNS servers as necessary
# The ramdisk's busybox does not have grep so check for a system busybox
if [ -e /system/xbin/busybox ]; then

RESOLVCONF=/system/etc/resolv.conf

if [ ! -f $RESOLVCONF ]; then
	> $RESOLVCONF
	chown 0.0 $RESOLVCONF
	chmod 644 $RESOLVCONF
fi

grep "4.2.2.2" $RESOLVCONF || echo "nameserver 4.2.2.2" >> $RESOLVCONF
grep "4.2.2.4" $RESOLVCONF || echo "nameserver 4.2.2.4" >> $RESOLVCONF
grep "8.8.8.8" $RESOLVCONF || echo "nameserver 8.8.8.8" >> $RESOLVCONF
grep "8.8.4.4" $RESOLVCONF || echo "nameserver 8.8.4.4" >> $RESOLVCONF

fi

# Add a little helper named ll to call "busybox ls -al"
if [ ! -x /system/xbin/ll ]; then
echo "busybox ls -al $*" > /system/xbin/ll
chmod 775 /system/xbin/ll
fi

# Remount system ro
mount -o ro,remount /system /system

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
