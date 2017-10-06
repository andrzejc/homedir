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
homedir_source xterm-titlebar.sh
homedir_source lessopen.sh

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
