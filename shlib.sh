[ -n "${__SHLIB_SOURCED:-}" ] && return
__SHLIB_SOURCED=1

# shstr_join <sep> <args...> - join arguments using sep as separator
shstr_join() {
    local sep="${1:-}"
    shift
    local res=""
    for s in "$@"
    do
        if [ -n "${res}" ]
        then
            if [ -n "${s}" ]
            then
                res="${res}${sep}${s}"
            fi
        else
            res="${s}"
        fi
    done
    echo "${res}"
}

shstr_alt() { shstr_join "|" "$@"; }

SHLIB_RAISE_LEVELS="ERROR FATAL"

sherr_should_raise() {
    local level="$1"
    for rl in ${SHLIB_RAISE_LEVELS:-FATAL}
    do
        [ "${level}" = "${rl}" ] && return 0
    done
    return 1
}

# sherr_raise <level> <args...> - overridable error handler function
#   invoked on
sherr_raise() {
    local level="${1:-ERROR}"
    exit -1
    # kill -s SIGABRT $$
}

# echo all args to stderr
sherr_echo() { echo -e "$@" >&2; }

shlog_dump() {
    local level="$1"
    shift
    sherr_echo "$@"
}

# shlog_format <level> <args...> - logging messages formatter,
# user-overridable
shlog_format() { shstr_join " " "$@"; }

shlog_() {
    local level="$1"
    shift
    # TODO add timestamp, formatting options etc, suppressing etc
    shlog_dump $(shlog_format "${level}" "$@")
    if sherr_should_raise "${level}" "$@"
    then
        sherr_raise "${level}" "$@"
    fi
}

shlog_warn()  { shlog_  WARNG  "$@"; }
shlog_warn_() { shlog_  WARNG  "$@"; }
shlog_debug() { shlog_  DEBUG  "$@"; }
shlog_error() { shlog_  ERROR  "$@"; }
shlog_fatal() { shlog_  FATAL  "$@"; }
shlog_info()  { shlog_ "INFO " "$@"; }
shlog_info_() { shlog_ "INFO " "$@"; }

SHLIB_ASSERT_ENABLED=0

sh_assert_() {
    if [ "${SHLIB_ASSERT_ENABLED:-0}" != 1 ]
    then
        return 0
    fi

    if [[ $# < 3 || $# > 4 ]]
    then
        local num=$(expr $# - 1)
        shlog_warn "sh_assert: wrong number of params ($num: $@)"
        return 1
    fi

    local lineno=$(caller 1)
    local cmd="\"$2\" $3 \"$4\""
    if [ $# -eq 3 ]
    then
        if [ "$2" "$3" ]
        then
            local success=1
        else
            local success=0
        fi
    else
        if [ "$2" "$3" "$4" ]
        then
            local success=1
        else
            local success=0
        fi
    fi
    if [ "${success}" != "$1" ]
    then
        shlog_ ASSRT "failed:  ${cmd}\n\tat $0(${lineno})"
        return 1
    fi
}

sh_assert()      { sh_assert_ 1 "$@"; }
sh_assert_fail() { sh_assert_ 0 "$@"; }

shpath_list() { shstr_join ":" "$@"; }

# shvar_get <var> - get value of dynamic variable
shvar_get() {
    sh_assert $# = 1
    local var="$1"
    eval "echo "\$\{${var}\}""
}

# shvar_set <var> <val> - set value of dynamic variable
shvar_set() {
    sh_assert $# -gt 0
    local var="$1"
    shift
    eval "${var}="$@""
}

shvar_name() {
    local path="$1"
    echo "${path}" | sed -e "s/[^_a-zA-Z0-9]/_/g"
}

__shlib_path_join_one() {
    sh_assert $# = 3
    local how="$1"
    local var="$2"
    local dir="$3"
    local var_val=$(shvar_get $var)

    [[ ":${var_val}:" != *":${dir}:"* ]] && {
        case "${how}" in
        before)
            local res="$(shpath_list "${dir}" "${var_val}")";;
        after)
            local res="$(shpath_list "${var_val}" "${dir}")";;
        *)
            shlog_warn "shpath_join: invalid 'how' value '${how}'"
            return 1;;
        esac
        shvar_set "${var}" "${res}"
        return
    } || return 0
}

# shpath_join <how> <var> <dir...> - append (how=after) or
#   prepend(how=before) directory to path list variable var provided it's not
#   included there yet
shpath_join() {
    local how="$1"
    local var="PATH"
    if [ $# -gt 2 ]
    then
        var="$2"
        shift
    fi
    shift
    for d in "$@"
    do
        __shlib_path_join_one "$how" "$var" "$d"
    done
}

shpath_pre() { shpath_join before "$@"; }
shpath_app() { shpath_join after  "$@"; }

# which suppressing error messsages
sh_which() { which "$@" 2> /dev/null; }

__shlib_test_shpath_join() {
    unset __shlib_test_shpath_join_res
    shpath_app __shlib_test_path_join_got a
    sh_assert "$__shlib_test_path_join_got" = "a"
    shpath_app __shlib_test_path_join_got pa
    sh_assert "$__shlib_test_path_join_got" = "a:pa"
    shpath_pre __shlib_test_path_join_got b
    sh_assert "$__shlib_test_path_join_got" = "b:a:pa"
    shpath_pre __shlib_test_path_join_got pb
    sh_assert "$__shlib_test_path_join_got" = "pb:b:a:pa"
    shpath_pre __shlib_test_path_join_got pr1 pr2
    sh_assert "$__shlib_test_path_join_got" = "pr2:pr1:pb:b:a:pa"
    shpath_app __shlib_test_path_join_got po1 po2
    sh_assert "$__shlib_test_path_join_got" = "pr2:pr1:pb:b:a:pa:po1:po2"
    export __shlib_test_path_join_got
}

# __shlib_test_shpath_join

__shlib_os_variant() {
    local os=$(uname -s)
    case $os in
    Linux)
        echo linux; return
        ;;
    Darwin)
        echo macos; return
        ;;
    *BSD)
        echo bsd; return
        ;;
    *)
        echo default; return
        ;;
    esac
}

SHLIB_OS_VARIANT=$(__shlib_os_variant)

sh_source_with_guard() {
    local file="$1"
    local flag="$2"
    if [ -r "${file}" ]
    then
        source "${file}"
        local res=$?
        shvar_set ${flag} 1
        return ${res}
    fi
    return 1
}