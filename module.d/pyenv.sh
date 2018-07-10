
setup_pyenv() {
	if [ -d "$HOME/.pyenv" ] && sh_which pyenv
	then
		shpath_pre "$HOME/.pyenv/bin"
		eval "$(pyenv init -)"
		if sh_which pyenv-virtualenv-init
		then
			eval "$(pyenv virtualenv-init -)"
		fi
	fi
}

setup_pyenv
