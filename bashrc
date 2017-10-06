if [ -f "$HOME/.bashrc.override" ]
then
	source "$HOME/.bashrc.override"
	exit $?
fi

if [ -f "$HOME/.bashrc.local" ]
then
	source "$HOME/.bashrc.local"
fi

if [ -f "$HOMEDIR/bashrc.$HOMEDIR_OS_VARIANT" ]
then
	source "$HOMEDIR/bashrc.$HOMEDIR_OS_VARIANT"
fi
