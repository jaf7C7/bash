hex2char() {
	# Usage: hex2char <hexcode> [<hexcode>...]
	#
	# Examples:
	#
	#     $ hex2char 0x68 0x65 0x6c 0x6c 0x6f
	#     hello
	#
	#     $ hex2char 0x0000203a
	#     ›
	#
	OLDIFS="$IFS"
	IFS=', '
	python -c "print(''.join(chr(c) for c in [${*}]))"
	IFS="$OLDIFS"
	unset OLDIFS
}

char2hex() {
	# Usage: char2hex <string> [<zero padding width>]
	#
	# Examples:
	#
	#     $ char2hex ›
	#     0x203a
	#
	#     $ char2hex › 8
	#     0x0000203a
	#
	#     $ char2hex hello
	#     0x68 0x65 0x6c 0x6c 0x6f
	#
	python -c "print(*['0x{:0${2:-}x}'.format(ord(c)) for c in '${1}'])"
}
