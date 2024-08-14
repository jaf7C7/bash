backup() {
	# Usage: backup [--poweroff]
	# A password for the network share and the sudo password are required.
	sudo -u jfox sh -c '
		echo mount --types cifs --options vers=1.0,user=jfox \
			//192.168.1.1/usb2_sda1 /mnt/network &&
		echo rsync --checksum --recursive --compress --verbose \
			--backup /home/jfox/Data /mnt/network/ &&
		test "$1" = '--poweroff' &&
		echo poweroff
	' "$@"
}
