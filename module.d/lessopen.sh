# setup less input/output preprocessor (LESSOPEN) env var

setup_lessopen() {
	local shs=$(sh_which src-hilite-lesspipe.sh)
	local lps=$(sh_which lesspipe.sh)

	if [ -x "${lps}" ]
	then
		eval "$(${lps})"
		# src-hilite-lesspipe.sh requires regular lesspipe
		if [ -x "${shs}" ]
		then
			export LESSOPEN="| "${shs}" %s"
			export LESS_ADVANCED_PROCESSOR=1
		fi
	fi
}

setup_lessopen