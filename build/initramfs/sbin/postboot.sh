#!/bin/sh
# Enable deep idle in sysfs
echo 1 > /sys/class/misc/deepidle/enabled

# Set internal storage read_ahead_kb
echo 512 > /sys/devices/virtual/bdi/179:0/read_ahead_kb

# Set sdcard read_ahead_kb
echo 1024 > /sys/devices/virtual/bdi/179:8/read_ahead_kb

# Write new kernel vm parameters
PSVM=/proc/sys/vm
echo 100 > $PSVM/vfs_cache_pressure
echo 20 > $PSVM/dirty_ratio
echo 5 > $PSVM/dirty_background_ratio
echo 200 > $PSVM/dirty_expire_centisecs
echo 500 > $PSVM/dirty_writeback_centisecs
echo 256 > $PSVM/lowmem_reserve_ratio
echo 4 > $PSVM/min_free_order_shift
echo 4096 > $PSVM/min_free_kbytes
echo 3 > $PSVM/page-cluster
echo 60 > $PSVM/swappiness
