
setup_pyenv() {
    [ -d "$HOME/.pyenv" ] && sh_which pyenv && {
        shpath_pre "$HOME/.pyenv/bin"
        eval "$(pyenv init -)"
        sh_which pyenv-virtualenv-init && eval "$(pyenv virtualenv-init -)"
        return
    } || return 0
}

setup_pyenv
