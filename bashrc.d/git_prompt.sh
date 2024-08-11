
__git_ps1() {
	command -v git &>/dev/null || return
	if git status -s &>/dev/null
	then
		local branch=$(git branch --show-current)
		printf ' (%s)' "${branch:-'???'}"
	fi
}
