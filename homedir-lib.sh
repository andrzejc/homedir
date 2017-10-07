[ -n "${__HOMEDIR_LIB_SOURCED:-}" ] && return
__HOMEDIR_LIB_SOURCED=1

source "$HOMEDIR/shlib.sh"

homedir_source() {
    local base="$1"
    local flag="__HOMEDIR_SOURCE_$(shvar_name "${base}")"
    if [ "$(shvar_get ${flag})" != 1 ]
    then
        sh_source_with_guard "$HOME/.${base}.override" ${flag} || \
        sh_source_with_guard "$HOMEDIR/${base}.${SHLIB_OS_VARIANT}" ${flag} || \
        sh_source_with_guard "$HOMEDIR/${base}" ${flag} || \
        shlog_warn "homedir_source ${base}: no variant found" && return 1
    fi
}

homedir_module() {
    homedir_source "profile.d/$1"
}