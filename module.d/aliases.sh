# start tmux in 256-color mode
[[ $TERM == *256col* ]] && alias tmux="tmux -2"

# list almost all
alias la='ls -A'
# list in columns with type suffixes (/@ etc)
alias l='ls -CF'
# list: long, almost all (hidden files, no ./..)
alias ll='ls -lA'
# lr:  Full Recursive Directory Listing
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'
 

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

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

zipf () { zip -r "$1".zip "$1" ; }          # zipf:         To create a ZIP archive of a folder

splitf () {
	local in="$1"
	local f="${in%.*}"
	local target="${HOME}/Music/nas/!WRZUTNIA/${f}"
	mkdir -p "${target}"
	shnsplit -f "${f}.cue" -t '%n-%t' -o flac -d "${target}" "${in}" && \
		rm "${f}.cue" "${in}"
}

