gitcheck() {
	# Usage: gitcheck
	#
	# Reports on all dirty git repositories under $HOME. Clean repos are
	# not reported.
	#
	find ~ -type d -name .git -exec sh -c '
		untracked_files() {
			git ls-files --other --directory --exclude-standard |
			grep -q '.'
		}

		uncommitted_changes() {
			! git diff --quiet >/dev/null 2>&1
		}

		print_status() {
			printf "\e[1;34m%s\e[m\n" "$PWD"
			git status -s
			echo
		}

		cd $(dirname $0) || exit

		if uncommitted_changes || untracked_files
		then
			print_status
		fi
	' {} \;
}
