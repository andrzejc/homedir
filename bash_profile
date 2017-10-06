#!/usr/bin/env bash
# shebang so that editor recognizes source 

export HOMEDIR="$( cd "$( dirname "$( readlink "${BASH_SOURCE[0]}" )" )" && pwd )"

if [ -f "$HOME/.bash_profile.override" ]
then
	source "$HOME/.bash_profile.override"
	exit $?
fi

if [ -f "$HOME/.bash_profile.local" ]
then
	source "$HOME/.bash_profile.local"
fi

if [ -d "$HOME/bin" ]
then
	export PATH="$HOME/bin:$PATH"
fi

homedir_os_variant() {
	local OS=$(uname -s)
	case $OS in
	Linux)
		echo linux; return
		;;
	Darwin)
		echo macos; return
		;;
	*BSD)
		echo bsd; return
		;;
	*)
		echo default; return
		;;
	esac
}

export HOMEDIR_OS_VARIANT=$(homedir_os_variant)

homedir_make_var_name() {
	local path="$1"
	echo "$path" | sed -e "s/[^_a-zA-Z0-9]/_/g"
}

__homedir_source_and_set_flag() {
	local file="$1"
	local flag="$2"
	if [ -f "$file" ]
	then
		source "$file"
		local res=$?
		eval "$flag=1"
		return $res
	fi
	return 1
}

homedir_source() {
	local base="$1"
	local var_name="__homedir_source_$( homedir_make_var_name "$base" )"
	if [ "$(eval "echo \$$var_name")" != "1" ]
	then
		__homedir_source_and_set_flag "$HOME/.${base}.override" "$var_name" ||\
		__homedir_source_and_set_flag "$HOMEDIR/${base}.${HOMEDIR_OS_VARIANT}" "$var_name" ||\
		__homedir_source_and_set_flag "$HOMEDIR/${base}" "$var_name" ||\
		>&2 echo "warning: homedir_source $base: no variant found" && return 1
	fi
}

export LESS=" -Rx4 "
export PAGER="less"
export EDITOR="vim"

homedir_source locale.sh
homedir_source ls-options.sh
homedir_source gcc-colors.sh
homedir_source ssh-agent.sh
homedir_source setup-prompt.sh

## If running within X Terminal or screen/tmux, use prompt to set tab title
xterm_titlebar_prompt() {
	case $TERM in
		xterm*|screen*)
			local TITLEBAR='\[\033]0;\u@${HOSTNAME_PROMPT}:\w\007\]'
			;;
		*)
			local TITLEBAR=''
			;;
	esac
	export PS1="${TITLEBAR}${PS1}"
}

if [ "x$XTERM_TITLE_PROMPT_DISABLE" != "x1" ]
then
	xterm_titlebar_prompt
fi

SRCHILITE_SH="$(which src-hilite-lesspipe.sh 2>/dev/null)"
LESSPIPE_SH="$(which lesspipe.sh 2>/dev/null)"

if [ -x "$SRCHILITE_SH" ]
then 
	export LESSOPEN="| $SRCHILITE_SH %s"
elif [ -x "$LESSPIPE_SH" ]
then
	export LESSOPEN="| $LESSPIPE_SH %s"
fi

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

if [ -f "$HOMEDIR/bash_profile.$HOMEDIR_OS_VARIANT" ]
then
	source "$HOMEDIR/bash_profile.$HOMEDIR_OS_VARIANT"
fi
