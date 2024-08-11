
bconv() {
	# Usage: bconv <input base> <output base> <number>.
	printf 'obase=%d; ibase=%d; %s\n' "$2" "$1" "${3@U}" | bc
}
