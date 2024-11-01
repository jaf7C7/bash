gitcheck() {
	# Usage: gitcheck
	#
	# Reports on all dirty git repositories under $HOME. Clean repos are
	# not reported.
	#
	find ~ -type d -name .git -exec sh -c '
		git_controlled() {
			git status -s
		} >/dev/null 2>&1

		untracked_files() {
			git ls-files --other --directory --exclude-standard |
			grep -q '.'
		} >/dev/null 2>&1

		uncommitted_changes() {
			! git diff --quiet >/dev/null 2>&1
		} >/dev/null 2>&1

		ahead_of_master() {
			git log --oneline origin/master..@ | grep -q '.'
		} >/dev/null 2>&1

		print_status() {
			printf "\e[1;34m%s\e[m\n" "$PWD"
			git status
		}

		cd $(dirname $0) || exit

		if git_controlled && {
			uncommitted_changes ||
			untracked_files ||
			ahead_of_master
		}
		then
			print_status
		fi
	' {} \;
}
