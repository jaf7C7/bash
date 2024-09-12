# termutils.bash
#
# Control terminal properties with escape sequences.
# https://invisible-island.net/xterm/ctlseqs/ctlseqs.html

__set_color() {
	# Usage: __set_color <0-15> {<#aabbcc>|<rgb:/aa/bb/cc>}
	#                   [<0-15> {<#aabbcc>|<rgb:/aa/bb/cc>}]...
	printf '\033]4;%d;%s\007' "$@"
}

__set_fg() {
	# Usage: __set_fg() {<#aabbcc>|<rgb:/aa/bb/cc>}
	printf '\033]10;%s\007' "$1"
}

__set_bg() {
	# Usage: __set_bg() {<#aabbcc>|<rgb:/aa/bb/cc>}
	printf '\033]11;%s\007' "$1"
}

__set_bold_fg() {
	# Usage: __set_bold_fg() {<#aabbcc>|<rgb:/aa/bb/cc>}
	printf '\033]5;0;%s\007' "$1"
}

__set_selection_fg() {
	# Usage: __set_selection_fg() {<#aabbcc>|<rgb:/aa/bb/cc>}
	printf '\033]17;%s\007' "$1"
}

__set_selection_bg() {
	# Usage: __set_selection_bg() {<#aabbcc>|<rgb:/aa/bb/cc>}
	printf '\033]19;%s\007'
}

__set_cursor_type() {
	# Usage: __set_cursor_type <number>
	# Cursor types:
	# 1 -> Blinking block
	#
	# TODO: Document this properly
	#
	printf '\033[%d q' "$1"
}

theme() {
	# Usage: theme [{default|solarized} [{dark|light}]]
	case $1 in
	default|'')
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

		case $2 in
		light|'')
			export TERMINAL_THEME=default-light
			local fg=$color8
			local bg=$color15
			;;
		dark)
			export TERMINAL_THEME=default-dark
			local fg=$color7
			local bg=$color8
			;;
		esac

		# Make sure all directory listings are readable.
		eval "$(dircolors | sed 's/00;90/00;33/g')"
		;;
	solarized)
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

		# XXX
		if [[ -r ~/.config/vim/pack/themes/opt/solarized8/scripts/solarized8.sh ]]
		then
			. ~/.config/vim/pack/themes/opt/solarized8/scripts/solarized8.sh
		fi

		case $2 in
		dark|'')
			export TERMINAL_THEME=solarized-dark
			local fg=$color12
			local bg=$color8
			local bold=$color14
			;;
		light)
			export TERMINAL_THEME=solarized-light
			local fg=$color11
			local bg=$color15
			local bold=$color10
			;;
		*)
			echo "Unknown theme: '$*'" >&2
			return 1
		esac

		eval "$(dircolors | sed 's/00;90/00;92/g')"
		;;
	*)
		echo "Unknown theme: '$*'" >&2
		return 1
	esac

	# Define 16-color palette.
	__set_color \
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
	__set_fg  "$fg"
	__set_bg "$bg"
	__set_bold_fg "${bold:-"$fg"}"
	__set_selection_fg "$fg"
	__set_selection_bg "$bg"
	__set_cursor_type 1
}

colortest() {
	# Usage: colortest
	#
	# TODO: Refactor this into helper functions
	#
	local bgv
	local i=0
	for bgv in 4 10
	do
		if ((bgv == 4))
		then
			printf ' \033[7m  %s   \033[m' fg
		else
			printf '   %s   '  bg
		fi
		local bg
		for bg in 0 1 2 3 4 5 6 7
		do
			printf ' \033[%d;%d%dm  %2d   \033[m' \
				$((bg == 7 || bg == 15 ? 0 : 97)) \
				"$bgv" "$bg" "$i"
			((i++))
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
			if [[ $cap == '0;0m' ]]
			then
				cap=m
			elif [[ $cap == '1;0m' ]]
			then
				cap=1m
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

