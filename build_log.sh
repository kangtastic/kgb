#!/bin/bash
DATE=$(date +%m%d)
TIME=$(date +%H%M)
bash build.sh 2>&1 | tee KGB-I500-"$DATE.$TIME".buildlog.txt
echo ""
echo "Log saved as KGB-I500-"$DATE.$TIME".buildlog.txt"
