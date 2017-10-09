[ -n "${__HOMEDIR_LIB_SOURCED:-}" ] && return
__HOMEDIR_LIB_SOURCED=1

source "$HOMEDIR/shlib.sh"

__homedir_os_variant() {
	local os=$(uname -s)
	case "$os" in
	Linux)  echo linux; return;;
	Darwin) echo macos; return;;
	*BSD)   echo bsd;   return;;
	*)      echo other; return;;
	esac
}

__HOMEDIR_DETECTED_OS_VARIANT=$(__homedir_os_variant)
HOMEDIR_OS_VARIANT=${HOMEDIR_OS_VARIANT:-${__HOMEDIR_DETECTED_OS_VARIANT}}

homedir_source() {
	local base="$1"
	local flag="__HOMEDIR_SOURCE_$(shvar_name "${base}")"
	local ext=""
	[[ "${base}" == *.sh ]] && {
		base="${base%.sh}"
		ext=".sh"
	}
	if [ "$(shvar_get ${flag})" != 1 ]
	then
		sh_source_with_guard "$HOME/.${base}.override${ext}" ${flag} || \
		sh_source_with_guard "$HOMEDIR/${base}.${HOMEDIR_OS_VARIANT}${ext}" ${flag} || \
		sh_source_with_guard "$HOMEDIR/${base}${ext}" ${flag} || \
		shlog_warn "homedir_source ${base}${ext}: no variant found" && return 1
	fi
}

HOMEDIR_MODULE_DIR="module.d"

homedir_module() {
	homedir_source "${HOMEDIR_MODULE_DIR}/$1"
}