#!/bin/sh
# Post-boot tweaks script

# New kernel vm parameters
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

# Enable deep idle in sysfs, although it's currently broken
# Apparently a ROM-dependent problem. Enable it anyway since the code's there
echo 1 > /sys/class/misc/deepidle/enabled

# Reset internal storage readahead; may have been changed by some dumbfuck's init.d script
# 179:0 corresponds to mmcblk0. On SCH-I500, this is eMMC (/data etc.) and NOT /sdcard
echo 128 > /sys/devices/virtual/bdi/179:0/read_ahead_kb

# Set sdcard readahead on the correct device
# 4096 may be too high latency. 1024 is next fastest value, even better than 2048 or 3072
echo 1024 > /sys/devices/virtual/bdi/179:8/read_ahead_kb

# End of script
