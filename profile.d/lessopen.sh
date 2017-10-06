# setup less input/output preprocessor (LESSOPEN) env var

SRCHILITE_SH="$(which src-hilite-lesspipe.sh 2>/dev/null)"
LESSPIPE_SH="$(which lesspipe.sh 2>/dev/null)"


if [ -x "$LESSPIPE_SH" ]
then
	eval "$( "$LESSPIPE_SH" )"
	# src-hilite-lesspipe.sh requires regular lesspipe
	if [ -x "$SRCHILITE_SH" ]
	then
		export LESSOPEN="| "$SRCHILITE_SH" %s"
		export LESS_ADVANCED_PROCESSOR=1
	fi
fi
