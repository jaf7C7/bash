# Do nothing if not interactive.
[[ $- == *i* ]] || return

[[ -f /etc/bashrc ]] && . /etc/bashrc

theme() {
	case "$1" in
	'clean'|'')
		local color0='#262626'
		local color1='#af0000'
		local color2='#008700'
		local color3='#af8700'
		local color4='#0000ff'
		local color5='#8700ff'
		local color6='#008080'
		local color7='#c0c0c0'
		local color8='#000000'
		local color9='#d70000'
		local color10='#5fd700'
		local color11='#d7d700'
		local color12='#0087ff'
		local color13='#d700ff'
		local color14='#00afaf'
		local color15='#ffffff'

		case "$2" in
		'light'|'')
			export TERMINAL_THEME='clean-light'
			local fg="$color8"
			local bg="$color15"
			;;
		'dark')
			export TERMINAL_THEME='clean-dark'
			local fg="$color7"
			local bg="$color8"
			;;
		esac

		eval "$(dircolors | sed 's/00;90/00;33/g')"
		;;
	'solarized')
		# https://github.com/altercation/solarized
		local color0='#073642'
		local color1='#DC322F'
		local color2='#859900'
		local color3='#B58900'
		local color4='#268BD2'
		local color5='#D33682'
		local color6='#2AA198'
		local color7='#EEE8D5'
		local color8='#002B36'
		local color9='#CB4B16'
		local color10='#586E75'
		local color11='#657B83'
		local color12='#839496'
		local color13='#6C71C4'
		local color14='#93A1A1'
		local color15='#FDF6E3'

		case "$2" in
		'dark'|'')
			export TERMINAL_THEME='solarized-dark'
			local fg="$color12"
			local bg="$color8"
			local bold="$color14"
			;;
		'light')
			export TERMINAL_THEME='solarized-light'
			local fg="$color11"
			local bg="$color15"
			local bold="$color10"
			;;
		*)
			echo "Unknown theme: '$*'" >&2
			return 1
		esac

		# Tweak `ls` colors to make everything readable.
		eval "$(dircolors | sed 's/00;90/00;92/g')"
		;;
	*)
		echo "Unknown theme: '$*'" >&2
		return 1
	esac

	# Control seqs. from:
	# https://invisible-island.net/xterm/ctlseqs/ctlseqs.html

	# Define 16-color palette.
	printf '\033]4;%d;%s\007' \
		0 "$color0" \
		1 "$color1" \
		2 "$color2" \
		3 "$color3" \
		4 "$color4" \
		5 "$color5" \
		6 "$color6" \
		7 "$color7" \
		8 "$color8" \
		9 "$color9" \
		10 "$color10" \
		11 "$color11" \
		12 "$color12" \
		13 "$color13" \
		14 "$color14" \
		15 "$color15"

	printf '\033]10;%s\007' "$fg"  # Text fg
	printf '\033]11;%s\007' "$bg"  # Text bg
	printf '\033]5;0;%s\007' "${bold:-"$fg"}" # Bold color
	printf '\033]17;%s\007' "$fg"  # Selection fg
	printf '\033]19;%s\007' "$bg"  # Selection bg
	printf '\033[%d q' 1		   # Cursor type (1=blinking block)
}

setc() {
	printf '\033]4;%d;%s\007' "$1" "$2"
}

colortest() {
	local bgv
	local i=0
	for bgv in 4 10
	do
		if test $((bgv)) -eq 4
		then
			printf ' \033[7m  %s   \033[m' fg
		else
			printf '   %s   '  bg
		fi
		local bg
		for bg in 0 1 2 3 4 5 6 7
		do
			printf ' \033[%d;%d%dm  %2d   \033[m' \
				$(($bg == 7 || $bg == 15 ? 0 : 97)) \
				"$bgv" "$bg" "$i"
			i=$((i + 1))
		done
		printf '\n'
	done
	printf '\n'

	local cap
	for cap in '' '' 40m 41m 42m 43m 44m 45m 46m 47m
	do
		printf '  %3s   ' "$cap"
	done
	printf '\n'

	local str='  gYw  '
	local fg
	for fg in 0 30 31 32 33 34 35 36 37
	do
		local wgt
		for wgt in 0 1
		do
			local cap="${wgt};${fg}m"
			if test "$cap" = '0;0m'
			then
				cap='m'
			elif test "$cap" = '1;0m'
			then
				cap='1m'
			fi
			# Stop 'fg' overriding 'wgt' for 'm' and '1m' lines.
			fg=$((wgt == 1  && fg == 0 ? 1 : fg))
			printf ' %5s ' "$cap"
			printf ' \033[%d;%dm%s\033[m' "$wgt" "$fg" "$str"
			for bg in 0 1 2 3 4 5 6 7
			do
				printf ' \033[%d;%d;4%dm%s\033[m' \
					"$wgt" "$fg" "$bg" "$str"
			done
			printf '\n'
		done
	done
}

resize() {
	# Usage: resize <cols> <rows> (default 80x43).
	printf '\033[8;%d;%dt' "${2:-43}" "${1:-80}"
}

bconv() {
	# Usage: bconv <input base> <output base> <number>.
	printf 'obase=%d; ibase=%d; %s\n' "$2" "$1" "${3@U}" | bc
}

__git_ps1() {
	command -v git &>/dev/null || return
	if git status -s &>/dev/null
	then
		local branch=$(git branch --show-current)
		printf ' (%s)' "${branch:-'???'}"
	fi
}

PS1='\$ '
PROMPT_COMMAND='printf "\e]0;%s\a" "${USER}@${HOSTNAME}:${PWD//$HOME/\~}$(__git_ps1)"'
CDPATH=.:~:~/Projects:~/Courses
HISTFILESIZE=1000000
HISTSIZE=10000
HISTIGNORE='[fb]g*:%*'
HISTCONTROL=ignoreboth

export EDITOR='vi'
export EXINIT='set cp hl=8r,~i,@b,dn,eb,mb,Mb,nb,rb,sr,Ss,tn,cr,vr,wb,Wn,+r,=n | map!  '
export LESSOPEN='||/usr/bin/lesspipe.sh %s'
export INPUTRC=~/.config/readline/inputrc
export MICRO_TRUECOLOR=1
export NPM_CONFIG_PREFIX=~/.local

if [[ -d "$HOME/.local/bin" && "$PATH" != "$HOME/.local/bin":* ]]
then
	PATH="$HOME/.local/bin:$PATH"
fi

shopt -s histappend  # Append to history file, don't overwrite
shopt -s globstar  # Allow '**'
shopt -s failglob  # Command fails if glob does not match

if [[ -x /usr/libexec/vi ]]
then
	# Fedora Linux only: 'vi' -> 'vim-minimal'
	alias vi=/usr/libexec/vi
fi
alias ls='ls --color'
alias grep='grep --color'
alias diff='diff --color'
alias open='xdg-open'
alias args='for _; do printf "%4d %s\\n" $((++i)) "$_"; done; unset i'
if [[ $OS == 'Windows_NT' ]]
then
	alias python='winpty python'
	alias node='winpty node'
	alias gh='winpty gh'
	alias open='explorer'
fi

# Disable Ctrl-S pausing input.
stty -ixon

set -o vi
bind '"\C-h": backward-kill-word'  # Ctrl-Backspace

cd "$HOME"
