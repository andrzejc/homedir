#!/usr/bin/env bash

BREW_OPT_DIR=/usr/local/opt

__brew_opt_path() {
	local package="$1"
	local path="$2"
	echo "${BREW_OPT_DIR}/${package}/${path}"
}

brew_opt() {
	local name="$1"
	local dir="$2"
	local how="$3"
	local var
	[ $# -gt 3 ] && var="$4" || var="PATH"
	local path="$(__brew_opt_path "${name}" "${dir}")"
	[ -d "${path}" ] && shpath_join "${how}" "${var}" "${path}" && export "$var"
}

BREW_OVERRIDES="$(cat <<-HERE
	python2 libexec/bin before PATH
	python2 lib/pkgconfig after PKG_CONFIG_PATH

	ccache libexec before PATH
	HERE
)"

setup_brew_overrides() {
	while read name dir how var
	do
		[ -n "${name}" ] && [ -n "${dir}" ] && [ -n "${how}" ] && \
			[ -n "${var}" ] && brew_opt "${name}" "${dir}" "${how}" "${var}"
	done <<< "${BREW_OVERRIDES}"
}

setup_brew_overrides