#!/bin/sh
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

busybox mount -o ro,remount /system
