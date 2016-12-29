if [ -f "$HOME/.bashrc.override" ]; then
	. "$HOME/.bashrc.override"
	exit $?
fi

# oh wait. iTerm2 shell integration. Do it before .bashrc.local, so it can 
# run tmux
test -e "${HOME}/.iterm2_shell_integration.bash" && \
	source "${HOME}/.iterm2_shell_integration.bash"

if [ -f "$HOME/.bashrc.local" ]; then
	. "$HOME/.bashrc.local"
fi


