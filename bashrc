# Do nothing if not interactive.
if [[ $- != *i* ]]
then
	return
fi

# Source system defaults if they exist.
if [[ -f /etc/bashrc ]]
then
	. /etc/bashrc
fi


#
# Shell variables (local to shell - not exported)
#

PS1='\$ '
PROMPT_COMMAND='printf "\e]0;%s\a" "${USER}@${HOSTNAME}:${PWD//$HOME/\~}$(__git_ps1)"'
CDPATH=.:~:~/Projects:~/Courses
HISTFILESIZE=1000000
HISTSIZE=10000
HISTIGNORE='[fb]g*:%*'
HISTCONTROL=ignoreboth


#
# Environment variables (global - exported to subprocesses)
#

if [[ -d "$HOME/.local/bin" && "$PATH" != "$HOME/.local/bin":* ]]
then
	export PATH="$HOME/.local/bin:$PATH"
fi
export EDITOR='vi'
export EXINIT='set nocp tm=10 ul=0 bs= ai ci sw=0 hidden cpo+=n backup backupdir=~/.config/vim/backups,.,~/ nosmd noru hl=8r,~i,@b,dn,eb,mb,Mb,nb,rb,sr,Ss,tn,cr,vr,wb,Wn,+r,=n | map!  '
export LESSOPEN='||/usr/bin/lesspipe.sh %s'
export INPUTRC=~/.config/readline/inputrc
export NPM_CONFIG_PREFIX=~/.local
export GIT_HOOKS=~/Projects/git-hooks
: "${TMP=${TEMP:=/tmp}}" ; export TMP TEMP


#
# Shell options
#

shopt -s histappend  # Append to history file, don't overwrite.
shopt -s globstar  # Allow recursive globbing with '**'.
shopt -s failglob  # Command fails if glob does not match.


#
# TTY options
#

stty -ixon  # Disable Ctrl-S pausing input.


#
# Readline options
#

set -o vi
test -r "$INPUTRC" || bind '"\C-h": backward-kill-word'  # Ctrl-Backspace.
if [[ -n $INSIDE_EMACS ]]
then
	unset PROMPT_COMMAND
	set -o emacs
fi


#
# Shell aliases
#

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


#
# Shell functions
#

# Usage:
# 	`args`: List shell arguments in index order.
# 	`e <int>`: Edit the argument at index `<int>`.
# 	`e <str>`: Edit the argument whose name matches `<str>`.
#
# Example:
# 	$ set -- foo.py bar.py
# 	$ args
#	   1 foo.py
#	   2 bar.py
#	$ e 2  # executes `vi bar.py`
#	$ e oo  # executes `vi foo.py`
#
alias args='i=0 ; for _ ; do printf "%4d %s\\n" $((++i)) "$_" ; done ; unset i'
alias e='__e "$@"'
__e() {
	local q
	eval "q=\${$#}"
	case "$q" in
	*[![:digit:]]*)
		# `$q` contains a non-digit character.
		while (( $# > 1 ))
		do
			# RHS must be *unquoted* to enable pattern matching.
			# https://mywiki.wooledge.org/BashGuide/TestsAndConditionals
			if [[ $1 == *${q}* ]]
			then
				q=$1
				break
			fi
			shift
		done ;;
	*)
		# `$q` contains only digits.
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


# Usage: PROMPT_COMMAND='printf "\e]0;%s\a" "${USER}@${HOSTNAME}:${PWD//$HOME/\~}$(__git_ps1)"'
#
# A much simplified (and much quicker) version of the prompt which ships
# with `git`.
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


# Usage: gitcheck
#
# Reports on all dirty git repositories under $HOME. Clean repos are
# not reported.
#
gitcheck() {
	find ~ -type d -name .git -exec sh -c '
		cd $(dirname $0) || exit

		__git_controlled() {
			git status -s
		} &>/dev/null

		__untracked_files() {
			git ls-files --other --directory --exclude-standard | grep -q '.'
		} &>/dev/null

		__uncommitted_changes() {
			! git diff --quiet >/dev/null
		} &>/dev/null

		__ahead_of_master() {
			git log --oneline origin/master..@ | grep -q '.'
		} &>/dev/null

		__print_status() {
			printf "\e[1;34m%s\e[m\n" "$PWD"
			git status
		}

		if __git_controlled && {
			__uncommitted_changes ||
			__untracked_files ||
			__ahead_of_master
		} then
			__print_status
		fi
	' {} \; 2>/dev/null
}


# Usage: serve <directory> [browser-sync options] &>serve.out &
#
# Serve contents of <directory>, watching all files.  Any long options will be
# passed to browser-sync.
#
# Execute this function in the background to stop it from blocking.
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
	browser-sync start --server "$dir" --files "$dir" "$@"
}


# Usage: mdprev <markdown_file> &>mdprev.out &
#
# Renders the markdown file as html, opening the rendered html in the browser
# and reloading the page when the file changes.
#
# Execute this function in the background to stop it from blocking.
#
mdprev() {
	if ! command -v entr &>/dev/null
	then
		echo 'entr required' >&2
		return 1
	fi
	if ! command -v browser-sync &>/dev/null
	then
		echo 'browser-sync required' >&2
		return 1
	fi
	local tmpdir=$(mktemp -d ${TMP}/mdprev_${1}_XXXXXXXX)
	local in=$1
	local out=${tmpdir}/index.html
	entr -n pandoc -so "$out" -M title:"$1" /_ <<<"$1" &
	trap "kill $!" RETURN
	browser-sync start -s "$tmpdir" -f "$out"
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

__set_terminal_cursor_color() {
	# TODO
	:
}

__set_terminal_cursor_size() {
	# TODO
	:
}

__set_terminal_size() {
	# TODO
	:
}
