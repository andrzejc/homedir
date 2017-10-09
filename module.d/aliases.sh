# start tmux in 256-color mode
[[ $TERM == *256col* ]] && alias tmux="tmux -2"

alias ll='ls -lAh'

cd() { builtin cd "$@"; ll; }

alias cd..='cd ../'

mcd() { mkdir -p "$1" && builtin cd "$1"; }


alias numf='echo $(ls -1 | wc -l)'          # numf:     Count of non-hidden files in current dir

alias ff='find . -name '                    # ff:       Find file under the current directory

#   extract:  Extract most know archives with one command
extract() {
	case "$1" in
	*.tar.bz2)   tar xjf "$1"     ;;
	*.tar.gz)    tar xzf "$1"     ;;
	*.bz2)       bunzip2 "$1"     ;;
	*.rar)       unrar e "$1"     ;;
	*.gz)        gunzip "$1"      ;;
	*.tar)       tar xf "$1"      ;;
	*.tbz2)      tar xjf "$1"     ;;
	*.tgz)       tar xzf "$1"     ;;
	*.zip)       unzip "$1"       ;;
	*.Z)         uncompress "$1"  ;;
	*.7z)        7z x "$1"        ;;
	*)
		shlib_warn "extract: unknown type of file '$1'" ;;
	esac
}

