#!/bin/bash
DATE=$(date +%m%d)
TIME=$(date +%H%M)
bash build.sh 2>&1 | tee TKSGB-I500-"$DATE.$TIME".buildlog.txt
echo ""
echo "Log saved as TKSGB-I500-"$DATE.$TIME".buildlog.txt"
