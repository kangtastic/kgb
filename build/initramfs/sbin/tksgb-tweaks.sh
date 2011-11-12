#!/system/bin/sh

# Remount rootfs and /system rw
busybox mount -t rootfs -o remount,rw rootfs
busybox mount -o rw,remount /system

	# Section 1: Tweaks in /system

# Install bootanimation binary
REFBANIM=/res/lib/bootanimation
SYSBANIM=/system/bin/bootanimation
if ! cmp $REFBANIM $SYSBANIM; then
	cat $REFBANIM > $SYSBANIM
	chown 0.2000 $SYSBANIM
	chmod 755 $SYSBANIM
fi

# Create /etc/init.d for callboost/zram scripts
busybox mkdir -p /system/etc/init.d

# Create resolv.conf, add in multicasted Verizon and Google DNS servers
RESOLVCONF=/system/etc/resolv.conf

if [ ! -f $RESOLVCONF ]; then
	busybox touch $RESOLVCONF
	chown 0.0 $RESOLVCONF
	chmod 644 $RESOLVCONF
fi

grep "4.2.2.2" $RESOLVCONF || echo "nameserver 4.2.2.2" >> $RESOLVCONF
grep "4.2.2.4" $RESOLVCONF || echo "nameserver 4.2.2.4" >> $RESOLVCONF
grep "8.8.8.8" $RESOLVCONF || echo "nameserver 8.8.8.8" >> $RESOLVCONF
grep "8.8.4.4" $RESOLVCONF || echo "nameserver 8.8.4.4" >> $RESOLVCONF

# Add a little helper named ll to call "busybox ls -al"
if [ ! -x /system/xbin/ll ]; then
echo "busybox ls -al $*" > /system/xbin/ll
chmod 775 /system/xbin/ll

# Remount /system read-only
sync
busybox mount -o remount,ro /system

	# Section 2: Kernel tweaks

# Set internal storage read_ahead_kb
echo 512 > /sys/devices/virtual/bdi/179:0/read_ahead_kb

# Set sdcard read_ahead_kb
echo 1024 > /sys/devices/virtual/bdi/179:8/read_ahead_kb


# Enable deep idle in sysfs
echo 1 > /sys/class/misc/deepidle/enabled

# Write new kernel vm parameters
PSVM=/proc/sys/vm
echo 100 > "$PSVM/vfs_cache_pressure"
echo 20 > "$PSVM/dirty_ratio"
echo 5 > "$PSVM/dirty_background_ratio"
echo 200 > "$PSVM/dirty_expire_centisecs"
echo 500 > "$PSVM/dirty_writeback_centisecs"
echo 256 > "$PSVM/lowmem_reserve_ratio"
echo 4 > "$PSVM/min_free_order_shift"
echo 4096 > "$PSVM/min_free_kbytes"
echo 3 > "$PSVM/page-cluster"
echo 60 > "$PSVM/swappiness"

# Bootanimation killer hack
while [ 1 ]; do
	sleep 1;
	if pgrep android.process.acore; then
		sleep 5;
		pkill bootanimation
		pkill samsungani
		break;
	fi
done
