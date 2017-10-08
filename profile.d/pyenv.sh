
setup_pyenv() {
    if [ -d "$HOME/.pyenv" ];
    then
        shpath_pre "$HOME/.pyenv/bin"
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
    fi
}

setup_pyenv