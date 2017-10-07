#!/usr/bin/env bash
# shebang so that editor recognizes source

__parent_dir() {
	local d="$1"
	[ -h "$d" ] && d=$(readlink "$d")
	(cd "$(dirname "$d")" && pwd)
}

export HOMEDIR="$(__parent_dir "${BASH_SOURCE[0]}")"

source "$HOMEDIR/homedir-lib.sh"

if [ -f "$HOME/.bash_profile.override" ]
then
	source "$HOME/.bash_profile.override"
	exit $?
fi

if [ -f "$HOME/.bash_profile.local" ]
then
	source "$HOME/.bash_profile.local"
fi

shpath_pre "$HOME/bin"
shpath_app "$HOMEDIR/bin"

export LESS=" -Rx4 "
export PAGER="less"
export EDITOR="vim"

homedir_module locale.sh
homedir_module ls-options.sh
homedir_module gcc-colors.sh
homedir_module ssh-agent.sh
homedir_module setup-prompt.sh
homedir_module xterm-titlebar.sh
homedir_module lessopen.sh
homedir_module brew-overrides.sh
homedir_module perl-local-lib.sh

#if [ -d "$HOME/.pyenv" ];
#then
#	export PATH="$HOME/.pyenv/bin:$PATH"
#	eval "$(pyenv init -)"
#	eval "$(pyenv virtualenv-init -)"
#fi

# start tmux in 256-color mode
if [[ $TERM == *256col* ]]
then
	alias tmux="tmux -2"
fi

alias ll='ls -lAhp'
cd() { builtin cd "$@"; ll; }
alias cd..='cd ../'
mcd() { mkdir -p "$1" && cd "$1"; }

#   ---------------------------
#   4.  SEARCHING
#   ---------------------------

alias numf='echo $(ls -1 | wc -l)'          # numf:     Count of non-hidden files in current dir
ff () { find . -name "$@" ; }               # ff:       Find file under the current directory
#ffs () { /usr/bin/find . -name "$@"'*' ; }  # ffs:      Find file whose name starts with a given string
#ffe () { /usr/bin/find . -name '*'"$@" ; }  # ffe:      Find file whose name ends with a given string

#   extract:  Extract most know archives with one command
#   ---------------------------------------------------------
extract () {
	if [ -f "$1" ]
	then
		case $1 in
		*.tar.bz2)   tar xjf $1     ;;
		*.tar.gz)    tar xzf $1     ;;
		*.bz2)       bunzip2 $1     ;;
		*.rar)       unrar e $1     ;;
		*.gz)        gunzip $1      ;;
		*.tar)       tar xf $1      ;;
		*.tbz2)      tar xjf $1     ;;
		*.tgz)       tar xzf $1     ;;
		*.zip)       unzip $1       ;;
		*.Z)         uncompress $1  ;;
		*.7z)        7z x $1        ;;
		*)     echo "'$1' cannot be extracted via extract()" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

if [ -f "$HOMEDIR/bash_profile.$HOMEDIR_OS_VARIANT" ]
then
	source "$HOMEDIR/bash_profile.$HOMEDIR_OS_VARIANT"
fi
