if [ ${__HOMEDIR_LIB_SOURCED:-0} = 0 ]
then

    __HOMEDIR_LIB_SOURCED=1
    export __HOMEDIR_ASSERT_ENABLED=1

    __homedir_fatal() {
        exit -1
        # kill -s SIGABRT $$
    }

    homedir_errcho() {
        echo "$@" >&2
    }

    homedir_log() {
        local level="$1"
        # TODO add timestamp, formatting options etc, suppressing etc
        homedir_errcho "${level} $@"
    }

    homedir_warn() {
        homedir_log WARNG "$@"
    }

    homedir_debug() {
        homedir_log DEBUG "$@"
    }

    homedir_error() {
        homedir_log ERROR "$@"
        __homedir_fatal
    }

    homedir_fatal() {
        homedir_log FATAL "$@"
        __homedir_fatal
    }

    homedir_info() {
        homedir_log "INFO " "$@"
    }

    __homedir_assert() {
        if [ "${__HOMEDIR_ASSERT_ENABLED:-0}" != 1 ]
        then
            return 0
        fi

        if [[ $# < 3 || $# > 4 ]]
        then
            local num=$(expr $# - 1)
            homedir_warn "homedir_assert: wrong number of params ($num: $@)"
            return 1
        fi

        local lineno=$(caller 1)
        local cmd="\"$2\" $3 \"$4\""
        if [ $# -eq 3 ]
        then
            if [ "$2" "$3" ]
            then
                local success=true
            else
                local success=false
            fi
        else
            if [ "$2" "$3" "$4" ]
            then
                local success=true
            else
                local success=false
            fi
        fi
        if [ "${success}" != "$1" ]
        then
            homedir_log  ASSRT "failed:  \"${cmd}\"\n      at \"$0\"(${lineno})"
            __homedir_fatal
        fi
    }

    homedir_assert() {
        __homedir_assert true "$@"
    }

    homedir_assert_fail() {
        __homedir_assert false "$@"
    }

    homedir_strjoin() {
        local sep="$1"
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

    homedir_path_list() {
        homedir_strjoin ":" "$@"
    }

    homedir_get() {
        local var="$1"
        eval "echo "\$\{${var}\}""
    }

    homedir_set() {
        local var="$1"
        shift
        eval "${var}="$@""
    }

    __homedir_path_munge_one() {
        local how="$1"
        local var="$2"
        local dir="$3"
        local var_val=$(homedir_get $var)

        [[ ":${var_val}:" != *":${dir}:"* ]] && {
            case ${how} in
            before)
                local res="$(homedir_path_list "${dir}" "${var_val}")";;
            after)
                local res="$(homedir_path_list "${var_val}" "${dir}")";;
            *)
                homedir_warn "homedir_path_munge: invalid 'how' value '${how}'"
                return 1;;
            esac
            homedir_set "${var}" "${res}"
            return
        } || return 0

    }

    # homedir_path_munge how var dir1 [dir...] - append (how=after) or
    #   prepend(how=before) directory to path list variable var provided it's not
    #   included there yet
    homedir_path_munge() {
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
            __homedir_path_munge_one "$how" "$var" "$d"
        done
    }

    homedir_path_prepend() {
        homedir_path_munge before "$@"
    }

    homedir_path_append() {
        homedir_path_munge after "$@"
    }

    # which suppressing error messsages
    homedir_which() {
        which "$@" 2> /dev/null
    }

    __homedir_lib_path_munge_test() {
        unset __HOMETEST_LIB_TEST_PATH_MUNGE
        homedir_path_append __HOMETEST_LIB_TEST_PATH_MUNGE after
        homedir_assert "$__HOMETEST_LIB_TEST_PATH_MUNGE" = "after"
        homedir_path_append __HOMETEST_LIB_TEST_PATH_MUNGE postafter
        homedir_assert "$__HOMETEST_LIB_TEST_PATH_MUNGE" = "after:postafter"
        homedir_path_prepend __HOMETEST_LIB_TEST_PATH_MUNGE before
        homedir_assert "$__HOMETEST_LIB_TEST_PATH_MUNGE" = "before:after:postafter"
        homedir_path_prepend __HOMETEST_LIB_TEST_PATH_MUNGE prebefore
        homedir_assert "$__HOMETEST_LIB_TEST_PATH_MUNGE" = "prebefore:before:after:postafter"
        homedir_path_prepend __HOMETEST_LIB_TEST_PATH_MUNGE pre1 pre2
        homedir_assert "$__HOMETEST_LIB_TEST_PATH_MUNGE" = "pre2:pre1:prebefore:before:after:postafter"
        homedir_path_append __HOMETEST_LIB_TEST_PATH_MUNGE post1 post2
        homedir_assert "$__HOMETEST_LIB_TEST_PATH_MUNGE" = "pre2:pre1:prebefore:before:after:postafter:post1:post2"
        export __HOMETEST_LIB_TEST_PATH_MUNGE
    }

    # __homedir_lib_path_munge_test

    __homedir_os_variant() {
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

    HOMEDIR_OS_VARIANT=$(__homedir_os_variant)

    homedir_variablize() {
        local path="$1"
        echo "${path}" | sed -e "s/[^_a-zA-Z0-9]/_/g"
    }

    __homedir_source_with_guard() {
        local file="$1"
        local flag="$2"
        if [ -r "${file}" ]
        then
            source "${file}"
            local res=$?
            homedir_set ${flag} 1
            return ${res}
        fi
        return 1
    }

    homedir_source() {
        local base="$1"
        local flag="__HOMEDIR_SOURCE_$(homedir_variablize "${base}")"
        if [ "$(homedir_get ${flag})" != 1 ]
        then
            __homedir_source_with_guard "$HOME/.${base}.override" ${flag} ||\
            __homedir_source_with_guard "$HOMEDIR/${base}.${HOMEDIR_OS_VARIANT}" ${flag} ||\
            __homedir_source_with_guard "$HOMEDIR/${base}" ${flag} ||\
            homedir_warn "homedir_source ${base}: no variant found" && return 1
        fi
    }

    homedir_module() {
        homedir_source "profile.d/$1"
    }

fi # !__HOMEDIR_LIB_SOURCED