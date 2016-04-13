if [ -f "$HOME/.bashrc.override" ]; then
	. "$HOME/.bashrc.override"
fi

# I'm starting to consider .bashrc unneccessary

if [ -f "$HOME/.bashrc.local" ]; then
	. "$HOME/.bashrc.local"
fi
