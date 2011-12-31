#!/bin/bash
DATE=$(date +%m%d)
TIME=$(date +%H%M)
# Run build.sh and pass any options on through
# Save STDERR separately from combined STDOUT+STDERR
LOG_ALL="KGB-$DATE.$TIME.buildlog.txt"
LOG_ERR="KGB-$DATE.$TIME.builderrlog.txt"
((./build.sh "$@" 2>&1 1>&3 | tee $LOG_ERR) 3>&1 1>&2) 2>&1 | tee $LOG_ALL
echo ""
echo "Logs saved as $LOG_ALL and $LOG_ERR"
