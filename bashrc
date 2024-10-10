# Do nothing if not interactive.
[[ $- == *i* ]] || return

[[ -f /etc/bashrc ]] && . /etc/bashrc

if [[ -d ~/.config/bash/bashrc.d ]]
then
	for _ in ~/.config/bash/bashrc.d/[!_]*.bash
	do
		. "$_"
	done
fi

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
export MICRO_TRUECOLOR=1
export NPM_CONFIG_PREFIX=~/.local

if [[ -d "$HOME/.local/bin" && "$PATH" != "$HOME/.local/bin":* ]]
then
	PATH="$HOME/.local/bin:$PATH"
fi

shopt -s histappend  # Append to history file, don't overwrite
shopt -s globstar  # Allow '**'
shopt -s failglob  # Command fails if glob does not match

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
if [[ $TERM_PROGRAM == 'vscode' ]] && command -v codium &>/dev/null
then
	alias code=codium
fi

# Disable Ctrl-S pausing input.
stty -ixon

set -o vi
bind '"\C-h": backward-kill-word'  # Ctrl-Backspace
