if [ -f "$HOME/.profile.override" ]; then
	. "$HOME/.profile.override"
	exit 0
fi

if [ -f "$HOME/.profile.local" ]; then
	. "$HOME/.profile.local"
fi

if [ -d "$HOME/bin" ]; then
	export PATH="$HOME/bin:$PATH"
fi

export LESS=" -R "
export PAGER="less"
export EDITOR="vim"

# Locale/time zone settings
export TZ="Europe/Warsaw"           # that's what it is
export LANG="en_US.UTF-8"           # don't want crappy polish translations
export LC_COLLATE="pl_PL.UTF-8"     # ...but sort order with ogonki is ok
export LC_TIME="pl_PL.UTF-8"        # as well as time format
export LC_CTYPE="pl_PL.UTF-8"
export LC_NUMERIC="pl_PL.UTF-8"
export LC_MONETARY="pl_PL.UTF-8"
export LC_PAPER="pl_PL.UTF-8"
export LC_NAME="pl_PL.UTF-8"
export LC_ADDRESS="pl_PL.UTF-8"
export LC_TELEPHONE="pl_PL.UTF-8"
export LC_MEASUREMENT="pl_PL.UTF-8"
export LC_IDENTIFICATION="pl_PL.UTF-8"

# Pull in ANSI color ids instead of numbers
. "$HOME/.ansi-colors.sh"

# ls colors & options
OS=$(uname -s)
case $OS in
	Linux)
		LS_COLOROPTS="--color=auto"
		export LS_COLORS="\
di=$ANSI_Blue:\
ln=$ANSI_Cyan:\
so=$ANSI_Magenta:\
pi=$ANSI_Yellow:\
ex=$ANSI_Green:\
bd=$ANSI_BG_Black;$ANSI_Yellow:\
cd=$ANSI_BG_Black;$ANSI_Yellow:\
su=$ANSI_Green;$ANSI_Bold:\
sg=$ANSI_Green;$ANSI_Bold:\
tw=$ANSI_Blue;$ANSI_Bold:\
ow=$ANSI_Blue;$ANSI_Bold:\
or=$ANSI_BG_Cyan;$ANSI_Black;$ANSI_Bold:\
mi=$ANSI_Red"
		;;
	*BSD|Darwin)
		LS_COLOROPTS="-G"
		#               di  so  ex  cd  sg  ow
		#                 ln  pi  bd  su  tw
		export LSCOLORS=exgxfxdacxdadaCxCxExEx
		;;
esac

# human-readable file sizes
export LS_OPTIONS="-h $LS_COLOROPTS"
alias ls="ls $LS_OPTIONS"

# Turn on GCC color output, if supported
export GCC_COLORS="\
error=$ANSI_Bold;$ANSI_Red:\
warning=$ANSI_Bold;$ANSI_Yellow:\
note=$ANSI_Bold;$ANSI_Cyan:\
caret=$ANSI_Bold;$ANSI_Green:\
locus=$ANSI_Bold:\
quote=$ANSI_Bold"

# Make sure .ssh exists and has proper permissions
SSH_DIR="$HOME/.ssh"
if [ ! -d "$SSH_DIR" ]; then
	mkdir "$SSH_DIR"
	chmod 700 "$SSH_DIR"
fi

# Start ssh-agent if not running
SSH_ENV="$SSH_DIR/environment"

function start_agent {
	echo "Initialising new SSH agent..."
	ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
	chmod 600 "${SSH_ENV}"
	. "${SSH_ENV}" > /dev/null
}

if [ "x$SSH_AGENT_DISABLE_AUTORUN" != "x1" ]; then
	if [ -f "${SSH_ENV}" ]; then
		. "${SSH_ENV}" > /dev/null
		ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
			start_agent;
		}
	else
		start_agent;
	fi
fi

# Setup shell prompt including Git status
. "$HOME/.git-prompt.sh"

# Use HOSTNAME_LOCAL in .profile.local to override displayed hostname
[ ! -z "$HOSTNAME_LOCAL" ] || HOSTNAME_LOCAL=$(hostname)

export GIT_PS1_SHOWDIRTYSTATE=1
export PS1="\
\[\033[$ANSI_Bold;${ANSI_Green}m\]\u@${HOSTNAME_LOCAL}\[\033[$ANSI_Bold;${ANSI_Blue}m\] \
\w\[\033[$ANSI_Bold;${ANSI_Yellow}m\]\$(__git_ps1 )\[\033[$ANSI_Bold;${ANSI_Blue}m\] \
\$\[\033[${ANSI_Default}m\] "

## If running within X Terminal or screen/tmux, use prompt to set tab title
xterm_titlebar_prompt() {
	case $TERM in
		xterm*|screen*)
			local TITLEBAR='\[\033]0;\u@${HOSTNAME_LOCAL}:\w\007\]'
			;;
		*)
			local TITLEBAR=''
			;;
	esac
	export PS1="${TITLEBAR}${PS1}"
}

if [ "x$XTERM_TITLE_PROMPT_DISABLE" != "x1" ]; then
	xterm_titlebar_prompt
fi

SRCHILITE_SH="$(which src-hilite-lesspipe.sh)"
LESSPIPE_SH="$(which lesspipe.sh)"

if [ -x "$SRCHILITE_SH" ]; then 
	export LESSOPEN="| $SRCHILITE_SH %s"
elif [ -x "$LESSPIPE_SH" ]; then
	export LESSOPEN="| $LESSPIPE_SH %s"
fi

# start tmux in 256-color mode
# TODO make it conditional on $TERM *-256color
alias tmux="tmux -2"
