#!/system/bin/sh

# Remount /system rw
busybox mount -t rootfs -o remount,rw rootfs
busybox mount -o remount,rw /system

# Install liblights
MD5SUM1=`busybox md5sum /system/lib/hw/lights.s5pc110.so | awk '{ print \$1 }'`
MD5SUM2=`busybox md5sum /res/lib/lights.s5pc110.so | awk '{ print \$1 }'`
if [ ! "$MD5SUM1" = "$MD5SUM2" ]; then
	busybox cp /system/lib/hw/lights.s5pc110.so /system/lib/hw/lights.s5pc110.so.old
	busybox cp -f /res/lib/lights.s5pc110.so /system/lib/hw/lights.s5pc110.so
	busybox chown root.root /system/lib/hw/lights.s5pc110.so
	busybox chmod 0644 /system/lib/hw/lights.s5pc110.so
fi

# Install bootanimation binary
MD5SUM1=`busybox md5sum /system/bin/bootanimation | awk '{ print \$1 }'`
MD5SUM2=`busybox md5sum /res/lib/bootanimation | awk '{ print \$1 }'`
if [ ! "$MD5SUM1" = "$MD5SUM2" ]; then
	busybox cp -f /res/lib/bootanimation /system/bin/bootanimation
	busybox chown root.shell /system/bin/bootanimation
	busybox chmod 0755 /system/bin/bootanimation
fi

# Fix up resolv.conf with multicasted Verizon and Google DNS
if [ ! -f "/system/etc/resolv.conf" ]; then
	echo "nameserver 4.2.2.4" >> /system/etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /system/etc/resolv.conf
fi
sync

# Set SD Card read_ahead_kb value
if [ -e /sys/devices/virtual/bdi/179:0/read_ahead_kb ]; then
	echo "1024" > /sys/devices/virtual/bdi/179:0/read_ahead_kb
fi

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

busybox mount -o remount,ro /system
