#!/usr/bin/env bash
set -e -o pipefail

__parent_dir() {
	local d="$1"
	[ -h "$d" ] && d=$(readlink "$d")
	(cd "$(dirname "$d")" && pwd)
}

TEST_DIR="$(__parent_dir "${BASH_SOURCE[0]}")"
SHLIB_ASSERT_ENABLED=1
source "$TEST_DIR/../shlib.sh"

test_shpath_join() {
    local got=""
    shpath_app got a
    sh_assert "$got" = "a"
    shpath_app got pa
    sh_assert "$got" = "a:pa"
    shpath_pre got b
    sh_assert "$got" = "b:a:pa"
    shpath_pre got pb
    sh_assert "$got" = "pb:b:a:pa"
    shpath_pre got pr1 pr2
    sh_assert "$got" = "pr2:pr1:pb:b:a:pa"
    shpath_app got po1 po2
    sh_assert "$got" = "pr2:pr1:pb:b:a:pa:po1:po2"
}

__test_shstr_join_one() {
    local exp="$1"
    shift
    local got="$(shstr_join "$@")"
    sh_assert "$exp" = "$got"
}

test_shstr_join() {
    __test_shstr_join_one ""
    __test_shstr_join_one "" ""
    __test_shstr_join_one "" "!"
    __test_shstr_join_one "" "!" ""
    __test_shstr_join_one "" "!" "" "" ""
    __test_shstr_join_one "foo" "" "foo"
    __test_shstr_join_one "foo" "!" "" "foo" ""
    __test_shstr_join_one "foobar" "" "foo" "bar"
    __test_shstr_join_one "foo!bar" "!" "foo" "bar"
    __test_shstr_join_one "foo!bar!baz" "!" "foo" "bar" "baz"
    __test_shstr_join_one "foo!bar!baz" "!" "" "foo" "" "bar" "" "baz" ""
    __test_shstr_join_one "foosepbarsepbaz" "sep" "" "foo" "" "bar" "" "baz" ""
    __test_shstr_join_one "abcdefg" "" a b c d e f g
}

__test_sherr_should_raise_one() {
    local args="$(shstr_join ' ' "$@")"
    local level="$1"
    local exp="$2"
    shift; shift
    local raise_levels="$@"
    local save_levels="${SHLIB_ERROR_RAISE_LEVELS:-}"
    SHLIB_ERROR_RAISE_LEVELS="$(shstr_join ' ' "$raise_levels")"
    if sherr_should_raise "$level"
    then
        local got=1
    else
        local got=0
    fi
    SHLIB_ERROR_RAISE_LEVELS="$save_levels"
    sh_assert "$exp" = "$got" || sherr_echo "\t${args}" && return 1
}

test_sherr_should_raise() {
    __test_sherr_should_raise_one FATAL 1 # FATAL always raises
    __test_sherr_should_raise_one ERROR 0
    __test_sherr_should_raise_one ERROR 1 ERROR
    __test_sherr_should_raise_one ERROR 1 ERROR FATAL
    __test_sherr_should_raise_one DEBUG 0 ERROR FATAL
}

gvar=3

test_shvar_get() {
    local lvar=1
    sh_assert $(shvar_get lvar) = 1
    lvar=2
    sh_assert $(shvar_get lvar) = 2

    gvar=3
    sh_assert $(shvar_get gvar) = 3
    gvar=4
    sh_assert $(shvar_get gvar) = 4

    shvar_set dvar 5
    sh_assert $(shvar_get dvar) = 5
    dvar=6
    sh_assert $(shvar_get dvar) = 6
}

test_shvar_set() {
    local lvar=1
    shvar_set lvar 2
    sh_assert ${lvar} = 2
    shvar_set lvar 3
    sh_assert ${lvar} = 3

    shvar_set gvar 4
    sh_assert ${gvar} = 4
    shvar_set gvar 5
    sh_assert ${gvar} = 5

    local dvar_name="dvar_$$"
    shvar_set ${dvar_name} 6
    sh_assert $(shvar_get ${dvar_name}) = 6
    shvar_set ${dvar_name} 7
    sh_assert $(shvar_get ${dvar_name}) = 7
}

test_shpath_join
test_shstr_join
test_sherr_should_raise
test_shvar_get
test_shvar_set