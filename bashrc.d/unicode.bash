# Convert between characters and their unicode codepoints.
# 
# XXX: Only works with single-byte characters

tochar() {
	# Usage: tochar 0000203a
	python -c "print(chr(0x${1}))"
}

fromchar() {
	# Usage: fromchar ›
	python -c "print(format(ord(\"${1}\"), '08x'))"
}

