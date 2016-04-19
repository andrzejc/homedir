
execute pathogen#infect()

syntax on
filetype plugin indent on

set backspace=indent,eol,start
" tab size, space width, auto indent
set ts=4 sw=4 ai
" laststatus
set ls=2

" don't display -- INSERT -- below airline
set noshowmode

if &encoding ==# 'latin1'
  set encoding=utf-8
endif

set pastetoggle=<f5>
set hlsearch
set incsearch
set ignorecase
set smartcase

" This allows buffers to be hidden if you've modified a buffer.
set hidden

if v:version > 703 || v:version == 703 && has("patch541")
  set formatoptions+=j " Delete comment character when joining commented lines
endif

" terminal 256 colors
set t_Co=256
set background=light

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme='powerlineish'

" Special characters for tab, trailing ws, eol, nbsp & horiz. scroll indicators
set list listchars=tab:»·,trail:˾,eol:↲,precedes:❰,extends:❱,nbsp:˽
" Leave vertical scroll margin of 1 line
set scrolloff=1
" Leave horizontal scroll margin of 5 chars
set sidescrolloff=5
" Indicate whitespace errors in C sources
let c_space_errors=1
" C source code indentation
set cindent
set smartindent

" Obey vim modelines as the one at the end of this file: vim:set ...
set modeline
" Show wrapped line continuation in (useless when wrapped) line number margin
set cpoptions+=n
" Enable use of mouse in N,I,V,C modes
set mouse=a

hi NonText ctermfg=LightGrey ctermbg=NONE
hi SpecialKey ctermfg=LightGrey ctermbg=NONE
hi Comment ctermfg=246 cterm=NONE

" Line numbers column
hi LineNr ctermbg=254 ctermfg=Gray
set number
set numberwidth=4

" Show current cursor line with slightly darker background
set cursorline
hi CursorLine cterm=NONE ctermbg=254
autocmd WinEnter * setlocal cursorline
autocmd WinLeave * setlocal nocursorline

" Display vertical var at columns 78,79,80
set textwidth=80
set colorcolumn=-2,-1,-0
highlight ColorColumn ctermbg=253 guibg=lightgray

if !empty(glob("~/.vimrc.local"))
  source ~/.vimrc.local
endif
" vim:set ft=vim et ts=2 sw=2:
