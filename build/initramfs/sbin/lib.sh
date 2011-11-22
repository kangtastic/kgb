# Helper functions for TKSGB scripts
system_rw()
{
busybox mount -o rw,remount /system
}
system_ro()
{
busybox mount -o ro,remount /system
}

fexist()
{
# Are all arguments existing files?
for FILEPATH in $@
do
	test -f $P
	if [ "$?" -ne "0" ]; then
		return 1
		break
	fi
done
}

show_options()
{
echo "
Usage: $1 [OPTION]
Valid options:

  enable    Enable custom $1 settings
            Install boot script
  disable   Remove boot script
            Disable custom $1 settings
  show      Display $1 status

Example: $1 show
"
}
