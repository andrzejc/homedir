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
