get_pid() {
	# Usage: get_pid <progname>
	ps ux | sed -n "1p;/[${1%${1#?}}]${1#?}/p" | less -XS
}
