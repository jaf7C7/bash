__git_ps1() {
	# A simplified (and much quicker) version of the prompt which ships
	# with `git(1)`.
	# Usage: Add `$(__git_ps1)` to your PS1 or PROMPT_COMMAND string.
	local branch=$(git branch --show-current 2>/dev/null)
	if [[ -n $branch ]]
	then
		printf ' (%s)' "${branch:-'???'}"
	fi
}
