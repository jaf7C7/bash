# Do nothing if not interactive.
if [[ $- != *i* ]]; then
    return
fi

# Source system defaults if they exist.
if [[ -f /etc/bashrc ]]; then
    . /etc/bashrc
fi

#
# Shell variables (local to shell - not exported)
#

PS1='\$ '
PROMPT_COMMAND='__prompt_command'
if [[ $TERM_PROGRAM == 'vscode' ]]; then
    PS1='\w \$ '
    unset PROMPT_COMMAND
fi
CDPATH=.:~:~/Projects:~/Courses
HISTFILESIZE=1000000
HISTSIZE=10000
HISTIGNORE='[fb]g*:%*'
HISTCONTROL=ignoreboth

#
# Environment variables (global - exported to subprocesses)
#

if [[ -d "$HOME/.local/bin" && "$PATH" != "$HOME/.local/bin":* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
export EDITOR='vi'
export EXINIT='set nocp tm=10 ul=0 bs= ai ci sw=0 hidden cpo+=n backup backupdir=~/.config/vim/backups,.,~/ nosmd noru hl=8r,~i,@b,dn,eb,mb,Mb,nb,rb,sr,Ss,tn,cr,vr,wb,Wn,+r,=n | map!  '
export LESSOPEN='||/usr/bin/lesspipe.sh %s'
export INPUTRC=~/.config/readline/inputrc
export NPM_CONFIG_PREFIX=~/.local
export GIT_HOOKS=~/Projects/git-hooks
: "${TMP=${TEMP:=/tmp}}"
export TMP TEMP

#
# Shell options
#

shopt -s globstar                # Allow recursive globbing with '**'.
shopt -s extglob                 # Allow extended pattern matching.
shopt -s histappend              # Append to history file, don't overwrite.
shopt -s lithist                 # Preserve formatting of multiline commands in history.
shopt -s no_empty_cmd_completion # Don't try to complete empty lines.
shopt -s checkjobs               # Warn about background jobs when exiting the shell.

#
# TTY options
#

stty -ixon # Disable Ctrl-S pausing input.

#
# Readline options
#

set -o vi
if [[ ! -r "$INPUTRC" ]]; then
    bind '"\C-h": backward-kill-word' # Ctrl-Backspace.
fi

#
# Shell aliases
#

alias ls='ls --color'
alias grep='grep --color'
alias diff='diff --color'
alias tree='tree --gitignore'
alias open='xdg-open'
alias sh='PS1=sh\$\  sh'
alias dash='PS1=dash\$\  dash'
if [[ -n $GNOME_TERMINAL_SCREEN ]]; then
    alias gt='gnome-terminal'
fi
if command -v flatpak &>/dev/null &&
    flatpak --app --columns=application list | grep -q 'com\.vscodium\.codium'
then
    alias code='2>/dev/null flatpak run com.vscodium.codium'
fi
if [[ $TERM_PROGRAM == 'vscode' ]] && command -v codium &>/dev/null; then
    alias code=codium
fi
if [[ $OS == 'Windows_NT' ]]; then
    alias python='winpty python'
    alias node='winpty node'
    alias gh='winpty gh'
    alias open='explorer'
fi

#
# Shell functions
#

# Usage: PROMPT_COMMAND='__prompt_command'
#
# Sets terminal title - e.g. `jfox@fedora:~/.config/bash (master)`
#
__prompt_command() {
    local str="${USER}@${HOSTNAME}:${PWD//$HOME/\~}$(__git_ps1)"
    if [[ $SHLVL -gt 1 && -z $TMUX ]]; then
        str="[${SHLVL}] ${str}"
    fi
    __set_terminal_title "$str"
}

# Usage:
#   `args`: Print a numbered list of shell arguments.
#   `e <int>`: Edit the argument at index `<int>`.
#   `e <str>`: Edit the argument whose name matches `<str>`.
#
# Easier file access and editing directly from the shell.
#
# Example:
#   $ set -- $(git ls-files \*.py)
#   $ args
#      1 foo.py
#      2 bar.py
#      3 baz.py
#   $ e 2  # executes `vi bar.py`
#   $ e foo  # executes `vi foo.py`
#
alias args='i=0 ; for _ ; do printf "%4d %s\\n" $((++i)) "$_" ; done ; unset i'
alias e='__e $# "${@:?}"'
__e() {
    local argc=$1
    shift
    if [[ $# -gt $(($argc + 1)) ]]; then
        shift $argc
        echo "too many arguments: $@" >&2
        return 1
    fi
    local sel=${@: -1:1}
    set -- "${@:1:$#-1}"
    case $sel in
        *[![:digit:]]*)
            local arg
            for arg; do
                shift
                if [[ $arg == *${sel}* ]]; then
                    set -- "$@" "$arg"
                fi
            done
            if [[ $# -gt 1 ]]; then
                echo "'$sel' matched multiple arguments: $@" >&2
                echo 'unique match required' >&2
                return 1
            fi
            if [[ $# -eq 0 ]]; then
                echo "'$sel' did not match any arguments" >&2
                return 1
            fi
            ;;
        *)
            if [[ $sel -gt $# || $sel -eq 0 ]]; then
                echo "'$sel' outside of argument range: 1-$#" >&2
                return 1
            fi
            set -- "${@:${sel}:1}"
            ;;
    esac
    "${EDITOR:-vi}" "$@"
}

# Usage: exec <command>
#
# Only exec <command> if there are no background jobs running.
#
exec() {
    if [[ -n $(jobs) ]]; then
        echo 'cannot exec: background jobs running' >&2
        jobs
        return 1
    fi
    builtin exec "$@"
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
        set -e
        if ! findmnt /mnt/network >/dev/null 2>&1; then
            mount \
                --types cifs \
                --options vers=1.0,user=jfox \
                //192.168.1.1/usb2_sda1 \
                /mnt/network
        fi
        rsync \
            --checksum \
            --recursive \
            --compress \
            --verbose \
            --backup \
            /home/jfox/Data \
            /mnt/network/
        if [ "$1" = "--poweroff" ]; then
            poweroff
        fi
    ' backup "$@"
}

# Usage: hex2char <hexcode> [<hexcode>...]
#
# Examples:
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
    python -c "print(*['0x{:0${2:-}x}'.format(ord(c)) for c in '${1:?}'])"
}

# Usage: uriencode <raw_URI>
#
# Encodes an entire URI string.
#
# Example:
#   $ uriencode 'https://example.com?param=echo "hello, world!"'
#   https://example.com?param=echo%20%22hello,%20world!%22
#
uriencode() {
    node -p "encodeURI('$1')"
}

# Usage: uridecode <encoded_URI>
#
# Decodes an entire URI string.
#
# Example:
#   $ uridecode 'https://example.com?param=echo%20%22hello,%20world!%22'
#   https://example.com?param=echo "hello, world!"
#
uridecode() {
    node -p "decodeURI('$1')"
}

# Usage: PROMPT_COMMAND='printf "\e]0;%s\a" "${USER}@${HOSTNAME}:${PWD//$HOME/\~}$(__git_ps1)"'
#
# A much simplified (and much quicker) version of the prompt which ships
# with `git`.
#
__git_ps1() {
    if ! git status -s &>/dev/null; then
        return
    fi
    local current=$(git branch --show-current)
    if [[ -z $current ]]; then
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
        cd "$(dirname $0)" || exit

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
            }
        then
            __print_status
        fi
    ' {} \; 2>/dev/null
}

# Usage: serve <directory> [browser-sync options]
#
# Serve contents of <directory>, watching all files.  Any long options will be
# passed to browser-sync.
#
# Example:
#   serve my_site &>serve.out &
#
serve() {
    local arg
    for arg; do
        shift
        if [[ "$arg" == --* ]]; then
            set -- "$@" "$arg"
            continue
        fi
        local dir="$arg"
        if [[ ! -d "$dir" ]]; then
            echo "not a directory: '$dir'" >&2
            return 1
        fi
        break
    done
    browser-sync start --server "$dir" --files "$dir" "$@"
}

# Usage: mdprev <markdown_file>
#
# Renders the markdown file as html, opening the rendered html in the browser
# and reloading the page when the file changes.
#
# Example:
#   mdprev foo.md &>mdprev.out &
#
mdprev() {
    if ! command -v entr &>/dev/null; then
        echo 'entr required' >&2
        return 1
    fi
    if ! command -v browser-sync &>/dev/null; then
        echo 'browser-sync required' >&2
        return 1
    fi
    local tmpdir=$(mktemp -d ${TMP}/mdprev_${1:?}_XXXXXXXX)
    local in=$1
    local out=${tmpdir}/index.html
    entr -n pandoc -so "$out" -M title:"$1" /_ <<<"$1" &
    trap "kill $!" RETURN
    browser-sync start -s "$tmpdir" -f "$out"
}

# Usage: termctl [-p|--passthrough] <command> [<args>...]
#
# Functions for configuring the terminal via escape sequences. The `-p` or
# `--passthrough` option wraps escape sequences in the tmux passthrough escape
# sequence.
#
# Tmux passthrough sequence:
# https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it
#
# Control sequences from `xterm(1)`:
# https://www.invisible-island.net/xterm/ctlseqs/ctlseqs.html
#
# Commands:
#   title [<title>]
#       Sets the new title set by `__prompt_command` to <title>, the
#       old value is saved.  If <title> is omitted, the old value is
#       restored.  Requires the `__prompt_command` function, and
#       `PROMPT_COMMAND='__prompt_command'` in `~/.bashrc`.
#
#   color <item> <color>
#       Sets the given item to color <color>. <color> can be a hex
#       value `#rrggbb` or an rgb value `rgb:rr/gg/bb` or a color name,
#       e.g. `deepseagreen`. <item> can be:
#       - fg
#       - bg
#       - selection-fg
#       - selection-bg
#       - cursor
#       - 0, 1, 2, ..., 15  (color index)
#
#   pallete 0 <color> 1 <color> ... 15 <color>
#       Sets each index 0-15 to the specified color. For setting an
#       entire palette at once.
#
#   theme <theme>
#       Sets the terminal theme to <theme>. <theme> can be:
#       - 'linux'
#       - 'solarized'
#       - 'light' (alias for 'linux')
#       - 'dark' (alias for 'solarized')
#       Themes set the foreground, background, color palette, and
#       selection foreground and background.
#
#   cursor <shape>
#       Sets cursor shape to <shape>. <shape> can be:
#       - 'block'
#       - 'bar'
#       - 'underline'
#       All cursors blink.
#
termctl() {
    local seq
    local passthrough
    case $1 in
        -p | --passthrough)
            passthrough='true'
            shift
            ;;
    esac
    case $1 in
        title)
            if [[ -n $2 ]]; then
                __OLD_PROMPT_COMMAND=$PROMPT_COMMAND
                PROMPT_COMMAND="__set_terminal_title '$2'"
            else
                shift
                PROMPT_COMMAND=$__OLD_PROMPT_COMMAND
                unset __OLD_PROMPT_COMMAND
            fi
            return 0
            ;;
        color)
            case $2 in
                fg)
                    seq=$(__set_terminal_fg "$3")
                    ;;
                bg)
                    seq=$(__set_terminal_bg "$3")
                    ;;
                selection-fg)
                    seq=$(__set_terminal_selection_fg "$3")
                    ;;
                selection-bg)
                    seq=$(__set_terminal_selection_bg "$3")
                    ;;
                cursor)
                    seq=$(__set_terminal_cursor_color "$3")
                    ;;
                [0-9] | 1[0-5])
                    seq=$(__set_terminal_palette "$2" "$3")
                    ;;
                *)
                    echo "Unknown color keyword: $2" >&2
                    return 1
                    ;;
            esac
            ;;
        palette)
            shift 2
            seq=$(__set_terminal_palette "$@")
            ;;
        theme)
            case $2 in
                linux | light)
                    seq=$(__set_linux_console_theme)
                    export TERMINAL_THEME='linux_console'
                    eval $(dircolors)
                    ;;
                solarized | dark)
                    seq=$(__set_solarized_theme)
                    export TERMINAL_THEME='solarized'
                    eval "$(dircolors | sed 's/00;90/00;92/g')"
                    ;;
                *)
                    echo "Unknown theme: $@" >&2
                    return 1
                    ;;
            esac
            ;;
        cursor)
            # Non-blinking cursor styles not implemented.
            case $2 in
                block)
                    seq=$(__set_terminal_cursor_shape 1)
                    ;;
                bar)
                    seq=$(__set_terminal_cursor_shape 5)
                    ;;
                underline)
                    seq=$(__set_terminal_cursor_shape 3)
                    ;;
                *)
                    echo "Unknown cursor style: $2" >&2
                    return 1
                    ;;
            esac
            ;;
        size)
            if [[ $# -lt 3 ]]; then
                echo "Usage: termctl size <lines> <columns>" >&2
                return 1
            fi
            seq=$(__set_terminal_size "$2" "$3")
            ;;
        *)
            echo "Unknown command: $1" >&2
            return 1
            ;;
    esac
    if [[ -n $passthrough ]]; then
        __tmux_passthrough '%s' "$seq"
    else
        printf '%s' "$seq"
    fi
}

__set_terminal_size() {
    # Usage: __set_terminal_size <lines> <columns>
    printf '\e[8;%d;%dt' "${1:?}" "${2:?}"
}

__set_terminal_title() {
    printf '\e]0;%s\a' "${1:?}"
}

__set_terminal_fg() {
    printf '\e]10;%s\a' "${1:?}"
}

__set_terminal_bg() {
    printf '\e]11;%s\a' "${1:?}"
}

__set_terminal_selection_fg() {
    printf '\e]19;%s\a' "${1:?}"
}

__set_terminal_selection_bg() {
    printf '\e]17;%s\a' "${1:?}"
}

__set_terminal_palette() {
    # Usage: __set_terminal_palette \
    #       0 '#000000' \
    #       1 '#ff0000' \
    #       2 '#00ff00' \
    #       ...
    printf '\e]4;%d;%s\a' "${@:?}"
}

__set_terminal_cursor_color() {
    printf '\e]12;%s\a' "${1:?}"
}

__set_terminal_cursor_style() {
    # 0  ⇒  blinking block.
    # 1  ⇒  blinking block (default).
    # 2  ⇒  steady block.
    # 3  ⇒  blinking underline.
    # 4  ⇒  steady underline.
    # 5  ⇒  blinking bar, xterm.
    # 6  ⇒  steady bar, xterm.
    printf '\e[%d q' "${1:?}"
}

__set_solarized_theme() {
    __set_terminal_fg '#839496'           # 12
    __set_terminal_bg '#002B36'           # 8
    __set_terminal_selection_fg '#EEE8D5' # 7
    __set_terminal_selection_bg '#6C71C4' # 13
    __set_terminal_palette \
        0 '#073642' \
        1 '#DC322F' \
        2 '#859900' \
        3 '#B58900' \
        4 '#268BD2' \
        5 '#D33682' \
        6 '#2AA198' \
        7 '#EEE8D5' \
        8 '#002B36' \
        9 '#CB4B16' \
        10 '#586E75' \
        11 '#657B83' \
        12 '#839496' \
        13 '#6C71C4' \
        14 '#93A1A1' \
        15 '#FDF6E3'
}

__set_linux_console_theme() {
    __set_terminal_fg '#000000'           # 0
    __set_terminal_bg '#FFFFFF'           # 15
    __set_terminal_selection_fg '#FFFFFF' # 15
    __set_terminal_selection_bg '#5555FF' # 12
    __set_terminal_palette \
        0 '#000000' \
        1 '#AA0000' \
        2 '#00AA00' \
        3 '#AA5500' \
        4 '#0000AA' \
        5 '#AA00AA' \
        6 '#00AAAA' \
        7 '#AAAAAA' \
        8 '#555555' \
        9 '#FF5555' \
        10 '#55FF55' \
        11 '#FFFF55' \
        12 '#5555FF' \
        13 '#FF55FF' \
        14 '#55FFFF' \
        15 '#FFFFFF'
}

__tmux_passthrough() {
    # Works like `printf` but wraps sequence in tmux passthrough sequence.
    #
    # Example: __tmux_passthrough '\e[%d q' 1
    #
    # https://github.com/tmux/tmux/wiki/FAQ
    printf "${@:?}" | awk '
        BEGIN {
            print("\033Ptmux;")
        }
        {
            gsub("\033", "\033\033")
            print($0)
        }
        END {
            print("\033\\")
        }
    '
}
