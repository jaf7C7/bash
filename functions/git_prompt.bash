__git_ps1() {
	# Usage: Add `$(__git_ps1)` to your PS1 or PROMPT_COMMAND string.
	#
	# A simplified (and much quicker) version of the prompt which ships
	# with `git(1)`.
	#
	if ! git status -s &>/dev/null
	then
		return
	fi
	local current=$(git branch --show-current)
	if [[ -z $current ]]
	then
		current=$(git rev-parse --short HEAD)
	fi
	printf ' (%s)' "$current"
}
