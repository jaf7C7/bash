backup() {
	# Usage: backup [--poweroff]
	# A password for the network share and the sudo password are required.
	sudo sh -c '
		mount --types cifs --options vers=1.0,user=jfox \
			//192.168.1.1/usb2_sda1 /mnt/network &&
		rsync --checksum --recursive --compress --verbose \
			--backup /home/jfox/Data /mnt/network/ &&
		test "$0" = '--poweroff' &&
		poweroff
	' "$@"
}
