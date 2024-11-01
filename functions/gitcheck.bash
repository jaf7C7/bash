gitcheck() {
	# Usage: gitcheck
	#
	# Reports on all dirty git repositories under $HOME. Clean repos are
	# not reported.
	#
	find ~ -type d -name .git -exec sh -c '
		cd $(dirname $0) || exit
		if { git status -s && ! git diff --quiet; } >/dev/null 2>&1
		then
			printf "\e[1;34m%s\e[m\n" "$PWD"
			git status -s
			echo
		fi
	' {} \;
}
