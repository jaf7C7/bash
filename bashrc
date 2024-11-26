# Do nothing if not interactive.
[[ $- == *i* ]] || return

[[ -f /etc/bashrc ]] && . /etc/bashrc

PS1='\$ '
PROMPT_COMMAND='printf "\e]0;%s\a" "${USER}@${HOSTNAME}:${PWD//$HOME/\~}$(__git_ps1)"'
CDPATH=.:~:~/Projects:~/Courses
HISTFILESIZE=1000000
HISTSIZE=10000
HISTIGNORE='[fb]g*:%*'
HISTCONTROL=ignoreboth

export EDITOR='vi'
export EXINIT='set nocp tm=10 ul=0 bs= ai ci sw=0 hidden cpo+=n backup backupdir=~/.config/vim/backups,.,~/ nosmd noru hl=8r,~i,@b,dn,eb,mb,Mb,nb,rb,sr,Ss,tn,cr,vr,wb,Wn,+r,=n | map!  '
export LESSOPEN='||/usr/bin/lesspipe.sh %s'
export INPUTRC=~/.config/readline/inputrc
export NPM_CONFIG_PREFIX=~/.local
export GIT_HOOKS=~/Projects/git-hooks

if [[ -d "$HOME/.local/bin" && "$PATH" != "$HOME/.local/bin":* ]]
then
	PATH="$HOME/.local/bin:$PATH"
fi

shopt -s histappend  # Append to history file, don't overwrite
shopt -s globstar  # Allow '**'
shopt -s failglob  # Command fails if glob does not match

# Disable Ctrl-S pausing input.
stty -ixon

set -o vi
bind '"\C-h": backward-kill-word'  # Ctrl-Backspace

alias ls='ls --color'
alias grep='grep --color'
alias diff='diff --color'
alias tree='tree --gitignore'
alias open='xdg-open'
if [[ $OS == 'Windows_NT' ]]
then
	alias python='winpty python'
	alias node='winpty node'
	alias gh='winpty gh'
	alias open='explorer'
fi
if [[ $TERM_PROGRAM == 'vscode' ]] && command -v codium &>/dev/null
then
	alias code=codium
fi
if [[ -n $INSIDE_EMACS ]]
then
	unset PROMPT_COMMAND
	set -o emacs
fi


# Usage: Add `$(__git_ps1)` to your PS1 or PROMPT_COMMAND string.
#
# A simplified (and much quicker) version of the prompt which ships
# with `git(1)`.
#
__git_ps1() {
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


# `args`: List shell arguments in index order.
# `e <int>`: Edit the argument at index `<int>`.
# `e <str>`: Edit the argument whose name matches `<str>`.
#
# Usage:
# 	$ set -- foo.py bar.py
# 	$ args
#	1 foo.py
#	2 bar.py
#	$ e 2  # executes `vi bar.py`
#	$ e oo  # executes `vi foo.py`
#
alias args='i=0 ; for _ ; do printf "%4d %s\\n" $((++i)) "$_" ; done ; unset i'
alias e='__edit_arg "$@"'
__edit_arg() {
	local q
	eval "q=\${$#}"
	case "$q" in
	*[![:digit:]]*)
		while (( $# > 1 ))
		do
			if [[ $1 == "*${q}*" ]]
			then
				q=$1
				break
			fi
			shift
		done ;;
	*)
		eval "q=\${$q}"
	esac
	"${EDITOR:-vi}" "$q"
}


# Usage: backup [--poweroff]
#
# Back up `~/Data` dir to the network drive. A password for the network
# share and the sudo password are required.
#
# `--poweroff` shuts the machine down after backing up.
#
backup() {
	sudo sh -c '
		mount --types cifs --options vers=1.0,user=jfox \
			//192.168.1.1/usb2_sda1 /mnt/network &&
		rsync --checksum --recursive --compress --verbose \
			--backup /home/jfox/Data /mnt/network/ &&
		test "$0" = "--poweroff" &&
		poweroff
	' "$@"
}


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
hex2char() {
	OLDIFS="$IFS"
	IFS=', '
	python -c "print(''.join(chr(c) for c in [${*}]))"
	IFS="$OLDIFS"
	unset OLDIFS
}


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
char2hex() {
	python -c "print(*['0x{:0${2:-}x}'.format(ord(c)) for c in '${1}'])"
}


# Usage: gitcheck
#
# Reports on all dirty git repositories under $HOME. Clean repos are
# not reported.
#
gitcheck() {
	__git_controlled() {
		git status -s
	} >/dev/null 2>&1

	__untracked_files() {
		git ls-files --other --directory --exclude-standard |
		grep -q '.'
	} >/dev/null 2>&1

	__uncommitted_changes() {
		! git diff --quiet >/dev/null 2>&1
	} >/dev/null 2>&1

	__ahead_of_master() {
		git log --oneline origin/master..@ | grep -q '.'
	} >/dev/null 2>&1

	__print_status() {
		printf "\e[1;34m%s\e[m\n" "$PWD"
		git status
	}

	local dir
	for dir in $(find ~ -type d -name .git)
	do
		cd $(dirname $0) || exit

		if __git_controlled && {
			__uncommitted_changes ||
			__untracked_files ||
			__ahead_of_master
		} then
			__print_status
		fi
	done
	unset \
		__git_controlled \
		__untracked_files \
		__uncommitted_changes \
		__ahead_of_master \
		__print_status
}


# Usage: serve <directory>
#
# Any long options will be passed to browser-sync.
#
serve() {
	local arg
	for arg
	do
		shift
		if [[ "$arg" == --* ]]
		then
			set -- "$@" "$arg"
			continue
		fi
		local dir="$arg"
		if [[ ! -d "$dir" ]]
		then
			echo "not a directory: '$dir'" >&2
			return 1
		fi
		break
	done
	gnome-terminal --tab -- \
		browser-sync start --server "$dir" --files "$dir" "$@"
}


# Functions for configuring the terminal.
#
# Colors can be hexcodes or color names: e.g. `#5fd7af` or `aquamarine3`.
#
# https://www.invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
#
__set_terminal_fg() {
	printf '\e]10;%s\a' "$1"
}

__set_terminal_bg() {
	printf '\e]11;%s\a' "$1"
}

__set_terminal_highlight_fg() {
	printf '\e]19;%s\a' "$1"
}

__set_terminal_highlight_bg() {
	printf '\e]17;%s\a' "$1"
}

__set_terminal_colors() {
	__set_terminal_fg '#000000'
	__set_terminal_bg '#eeffcc'
	__set_terminal_hl_bg '#5555ff'
	__set_terminal_hl_fg '#ffffff'
}
