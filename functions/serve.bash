serve() {
	# Usage: serve <directory>
	if ! test -d "$1"
	then
		echo "Not a directory: '$1'" >&2
		return 1
	fi
	gnome-terminal --tab -- browser-sync start --server "$1" --files "$1"
}
