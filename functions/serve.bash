serve() {
	# Usage: serve <directory>
	#
	# Any long options will be passed to browser-sync
	#
	local arg
	for arg
	do
		shift
		if [[ "$arg" == --* ]]
		then
			set -- "$arg"
			continue
		fi
		local dir="$arg"
		if [[ ! -d "$dir" ]]
		then
			echo "not a directory: '$dir'" >&2
			return 1
		fi
		break
	done
	gnome-terminal --tab -- \
		browser-sync start --server "$dir" --files "$dir" "$@"
}
