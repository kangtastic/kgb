#!/system/bin/sh

# Remount rootfs and /system rw
busybox mount -t rootfs -o remount,rw rootfs
busybox mount -o rw,remount /system

# Install bootanimation binary
REFBANIM=/res/lib/bootanimation
SYSBANIM=/system/bin/bootanimation
if ! cmp $REFBANIM $SYSBANIM; then
	cat $REFBANIM > $SYSBANIM
	chown 0.2000 $SYSBANIM
	chmod 755 $SYSBANIM
fi

# If necessary create resolv.conf with multicasted Verizon and Google DNS
if [ ! -f /system/etc/resolv.conf ]; then
	echo "nameserver 4.2.2.4" > /system/etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /system/etc/resolv.conf
fi
sync

# Set SD Card read_ahead_kb value
if [ -e /sys/devices/virtual/bdi/179:0/read_ahead_kb ]; then
	echo "1024" > /sys/devices/virtual/bdi/179:0/read_ahead_kb
fi

# Enable deep idle in sysfs
	echo "1" > /sys/class/misc/deepidle/enabled

# Bootanimation hack
while [ 1 ]; do
	sleep 1;
	if pgrep android.process.acore; then
		sleep 5;
		busybox pkill bootanimation
		busybox pkill samsungani
		exit;
	fi
done

# Add a little helper for "busybox ls -al"
if [ ! -x /system/xbin/ll ]; then
echo "busybox ls -al $*" > /system/xbin/ll
chmod 777 /system/xbin/ll

busybox mount -o remount,ro /system
