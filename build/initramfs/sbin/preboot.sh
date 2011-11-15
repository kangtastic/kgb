#!/bin/sh
# Pre-boot tweaks script

# Remount rootfs rw, system rw and noatime
busybox mount -t rootfs -o remount,rw rootfs
busybox mount -o rw,remount,noatime /system

# Install bootanimation binary as necessary
REFBANIM=/res/lib/bootanimation
SYSBANIM=/system/bin/bootanimation
if ! cmp $REFBANIM $SYSBANIM; then
	cat $REFBANIM > $SYSBANIM
	chown 0.2000 $SYSBANIM
	chmod 755 $SYSBANIM
fi

# Create /etc/init.d as necessary
busybox mkdir -p /system/etc/init.d

# Create resolv.conf, add multicasted Verizon and Google DNS servers as necessary
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
fi

# Remount system ro. End of script
busybox mount -o ro,remount /system
