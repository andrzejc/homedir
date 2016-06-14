if [ -f "$HOME/.bashrc.override" ]; then
	. "$HOME/.bashrc.override"
fi

# I'm starting to consider .bashrc unneccessary

if [ -f "$HOME/.bashrc.local" ]; then
	. "$HOME/.bashrc.local"
fi

# oh wait. iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.bash" && \
	source "${HOME}/.iterm2_shell_integration.bash"
