# ls colors & options
case $HOMEDIR_OS_VARIANT in
	linux)
		LS_COLOROPTS="--color=auto"
		export LS_COLORS="\
di=$ANSI_Blue:\
ln=$ANSI_Cyan:\
so=$ANSI_Magenta:\
pi=$ANSI_Yellow:\
ex=$ANSI_Green:\
bd=$ANSI_BG_Black;$ANSI_Yellow:\
cd=$ANSI_BG_Black;$ANSI_Yellow:\
su=$ANSI_Green;$ANSI_Bold:\
sg=$ANSI_Green;$ANSI_Bold:\
tw=$ANSI_Blue;$ANSI_Bold:\
ow=$ANSI_Blue;$ANSI_Bold:\
or=$ANSI_BG_Cyan;$ANSI_Black;$ANSI_Bold:\
mi=$ANSI_Red"
		;;
	bsd|macos)
		LS_COLOROPTS="-G"
		#               di  so  ex  cd  sg  ow
		#                 ln  pi  bd  su  tw
		export LSCOLORS=exgxfxdacxdadaCxCxExEx
		;;
esac



# human-readable file sizes
export LS_OPTIONS="-h $LS_COLOROPTS"
alias ls="ls $LS_OPTIONS"


