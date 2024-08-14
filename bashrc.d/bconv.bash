bconv() {
	# Convert between decimal, hexadecimal, binary, octal etc.
	# Usage: bconv <input base> <output base> <number>.
	if ! command -v bc >/dev/null
	then
		echo '`bc(1)` is required to use this function' >&2
		return 1
	fi
	printf 'obase=%d; ibase=%d; %s\n' "$2" "$1" "${3@U}" |
	bc |
	tr '[[:upper:]]' '[[:lower:]]'  # Lowercase letters for readability.
}
