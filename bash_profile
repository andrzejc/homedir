#!/usr/bin/env bash
# shebang so that editor recognizes source

__parent_dir() {
	local d="$1"
	[[ "$d" == /* ]] || d="$HOME/$d"
	[ -h "$d" ] && d="$(readlink "$d")"
	[[ "$d" == /* ]] || d="$HOME/$d"
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
# homedir_module perlbrew.sh
homedir_module perl-local-lib.sh
homedir_module pyenv.sh
homedir_module aliases.sh
homedir_module git-completion.sh

if [ -f "$HOMEDIR/bash_profile.$HOMEDIR_OS_VARIANT" ]
then
	source "$HOMEDIR/bash_profile.$HOMEDIR_OS_VARIANT"
fi
