# Turn on GCC color output, if supported
homedir_module ansi-colors.sh

export GCC_COLORS="\
error=$ANSI_Bold;$ANSI_Red:\
warning=$ANSI_Bold;$ANSI_Yellow:\
note=$ANSI_Bold;$ANSI_Cyan:\
caret=$ANSI_Bold;$ANSI_Green:\
locus=$ANSI_Bold:\
quote=$ANSI_Bold"


