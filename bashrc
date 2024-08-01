# Do nothing if not interactive.
[[ $- == *i* ]] || return

[[ -f /etc/bashrc ]] && . /etc/bashrc

theme() {
	case "$1" in
	'vga'|'')
		# 'Linux console' palette from gnome-terminal.
		local color0='#000000'
		local color1='#AA0000'
		local color2='#00AA00'
		local color3='#AA5500'
		local color4='#0000AA'
		local color5='#AA00AA'
		local color6='#00AAAA'
		local color7='#AAAAAA'
		local color8='#555555'
		local color9='#FF5555'
		local color10='#55FF55'
		local color11='#FFFF55'
		local color12='#5555FF'
		local color13='#FF55FF'
		local color14='#55FFFF'
		local color15='#FFFFFF'

		case "$2" in
		'light'|'')
			export TERMINAL_THEME='vga-light'
			local fg="$color0"
			local bg="$color15"
			;;
		'dark')
			export TERMINAL_THEME='vga-dark'
			local fg="$color7"
			local bg="$color0"
			;;
		esac
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
	'gruvbox')
		# https://github.com/morhetz
		local black0='#282828'
		local black1='#3c3836'
		local black3='#665c54'
		local black4='#7c6f64'
		local red='#9d0006'
		local green='#79740e'
		local yellow='#b57614'
		local orange='#af3a03'
		local blue='#076678'
		local purple='#8f3f71'
		local aqua='#427b58'
		local gray='#928374'
		local brightred='#fb4934'
		local brightgreen='#b8bb26'
		local brightyellow='#fabd2f'
		local brightorange='#fe8019'
		local brightblue='#83a598'
		local brightpurple='#d3869b'
		local brightaqua='#8ec07c'
		local white0='#fbf1c7'
		local white1='#ebdbb2'
		local white3='#bdae93'
		local white4='#a89984'

		case "$2" in
		'dark'|'')
			export TERMINAL_THEME='gruvbox-dark'
			local color0="$black0"
			local color1="$brightred"
			local color2="$brightgreen"
			local color3="$brightyellow"
			local color4="$brightblue"
			local color5="$brightpurple"
			local color6="$brightaqua"
			local color7="$white1"
			local color8="$black3"
			local color9="$brightorange"
			local color10="$black1"
			local color11="$black4"
			local color12="$gray"
			local color13="$white4"
			local color14="$white3"
			local color15="$white0"
			local bg="$black0"
			local fg="$white1"
			;;
		'light')
			export TERMINAL_THEME='gruvbox-light'
			local color0="$white0"
			local color1="$red"
			local color2="$green"
			local color3="$yellow"
			local color4="$blue"
			local color5="$purple"
			local color6="$aqua"
			local color7="$black1"
			local color8="$white3"
			local color9="$orange"
			local color10="$white1"
			local color11="$white4"
			local color12="$gray"
			local color13="$black4"
			local color14="$black3"
			local color15="$black0"
			local bg="$white0"
			local fg="$black1"
			;;
		*)
			echo "Unknown theme: '$*'" >&2
			return 1
		esac

		# Override terminal colors with gruvbox palette.
		source ~/.config/vim/plugged/gruvbox/gruvbox_256palette.sh
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
	if git status -s &>/dev/null; then
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
export LESSOPEN='||/usr/bin/lesspipe.sh %s'
export INPUTRC=~/.config/readline/inputrc
export MICRO_TRUECOLOR=1
export NPM_CONFIG_PREFIX=~/.local

if [[ -d "$HOME/.local/bin" && "$PATH" != "$HOME/.local/bin":* ]]; then
	PATH="$HOME/.local/bin:$PATH"
fi

shopt -s histappend	 # Append to history file, don't overwrite
shopt -s globstar  # Allow '**'
shopt -s failglob  # Command fails if glob does not match

alias ls='ls --color'
alias grep='grep --color'
alias diff='diff --color'
alias open='xdg-open'

if [[ $OS == 'Windows_NT' ]]; then
	alias python='winpty python'
	alias node='winpty node'
	alias gh='winpty gh'
fi

# Disable Ctrl-S pausing input.
stty -ixon

set -o vi
bind '"\C-h": backward-kill-word'  # Ctrl-Backspace

#theme solarized
