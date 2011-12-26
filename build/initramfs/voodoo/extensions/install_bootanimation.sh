# Voodoo lagfix extension

name='bootanimation binary for .zip boot animation support'

source='/voodoo/extensions/bootanimation/bootanimation'
dest="/system/bin/bootanimation"
backup="$dest-backup-"`date '+%Y-%m-%d_%H-%M-%S'`

install_condition()
{
	test -f /data/local/bootanimation.zip || \
	test -f /system/media/bootanimation.zip || \
	test -f /system/media/sanim.zip
}

extension_install_bootanimation()
{
	# be nice, make a backup please
	mv $dest $backup
	cp $source $dest
	# make sure it's owned by root
	# set default permissions
	chown 0.2000 $dest && chmod 755 $dest && log "$name now installed" || \
		log "problem during $name installation"

}

if install_condition; then
	if ! cmp $source $dest; then
		extension_install_bootanimation
	else
		# ours is the same don't touch it
		log "$name already installed"
	fi
else
	log "$name cannot be installed or is not supported"
fi
