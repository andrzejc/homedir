# Setup shell prompt including Git status
homedir_source git-prompt.sh
homedir_source ansi-colors.sh

# Use HOSTNAME_LOCAL in .profile.local to override displayed hostname
HOSTNAME_PROMPT="${HOSTNAME_LOCAL:-$(hostname)}"

# affects working of __git_ps1 function below, taken from git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1

export PS1="\
\[\033[$ANSI_Bold;${ANSI_Green}m\]\u@${HOSTNAME_PROMPT}\
\[\033[$ANSI_Bold;${ANSI_Blue}m\] \w\[\033[$ANSI_Bold;${ANSI_Yellow}m\]\
\$(__git_ps1 )\[\033[$ANSI_Bold;${ANSI_Blue}m\] \$\[\033[${ANSI_Default}m\] "
