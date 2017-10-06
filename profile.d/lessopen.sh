# setup less input/output preprocessor (LESSOPEN) env var

SRCHILITE_SH="$(which src-hilite-lesspipe.sh 2>/dev/null)"
LESSPIPE_SH="$(which lesspipe.sh 2>/dev/null)"


if [ -x "$LESSPIPE_SH" ]
then
	export LESSOPEN="| $LESSPIPE_SH %s"
	# src-hilite-lesspipe.sh requires regular lesspipe
	if [ -x "$SRCHILITE_SH" ]
	then
		alias lesspipe="$LESSPIPE_SH"
		eval "$( "$SRCHILITE_SH" )"
	fi
fi
