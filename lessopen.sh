SRCHILITE_SH="$(which src-hilite-lesspipe.sh 2>/dev/null)"
LESSPIPE_SH="$(which lesspipe.sh 2>/dev/null)"

if [ -x "$SRCHILITE_SH" ]
then 
	export LESSOPEN="| $SRCHILITE_SH %s"
elif [ -x "$LESSPIPE_SH" ]
then
	export LESSOPEN="| $LESSPIPE_SH %s"
fi
