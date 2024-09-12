uni() {
	# Print any unicode char by its codepoint. Leading zeroes can be omitted.
	# Usage: uni 1fa82
	# 🪂
	while (( ${#1} < 8 ))
	do
		set -- "0${1}"
	done
	printf "\\U${1}\\n"
}
