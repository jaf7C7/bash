# `termutils.bash` Functions for configuring the terminal.
#
# https://www.invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
#
# Colors can be hexcodes or color names

__set_terminal_bg {
	printf '\e]11;%s\a' "$1"
}

__set_terminal_fg {
	printf '\e]10;%s\a' "$1"
}

__set_terminal_highlight_fg {
	printf '\e]19;%s\a' "$1"
}

__set_terminal_highlight_bg {
	printf '\e]17;%s\a' "$1"
}

__set_terminal_colors() {
	__set_terminal_fg '#000000'
	__set_terminal_bg '#eeffcc'
	__set_terminal_hl_bg '#5555ff'
	__set_terminal_hl_fg '#ffffff'
}
