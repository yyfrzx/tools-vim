syntax on
filetype indent plugin on
filetype on
set tabstop=4 
set expandtab
set shiftwidth=4
set softtabstop=4
set number 
set modeline 
set linespace=6
let g:pydiction_location='~/.vim/pydiction-master/complete-dict'  
set autoindent
set clipboard=unnamed
imap <c-z> <esc>:undo<cr>
nmap <c-\> <esc>gg=G``
nmap <return> <c-]>
nmap <space> <c-t>
nmap <c-[> :cs find c <C-R>=expand("<cword>")<cr><cr>
map <C-F12> :!ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .<cr>

execute pathogen#infect()

let g:SuperTabDefaultCompletionType="context"   
"set cscopequickfix=s-,c-,d-,i-,t-,e-  
"
"

"let g:indent_guides_auto_colors = 0
"autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=gray   ctermbg=7
"autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=gray   ctermbg=7

filetype plugin on
let g:pydiction_location = '~/.vim/vim/pydiction/complete-dict'

"let g:pydiction_menu_height = 3

let g:pyflakes_use_quickfix = 0

nmap <right> :bn<cr>
nmap <left> :bp<cr>
nmap <C-h> <C-w>h
nmap <C-l> <C-w>l
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
imap <C-e> <esc>$i 
nmap <C-e> <esc>$
imap <C-a> <esc>0i
nmap <C-a> <esc>^
""nmap <C-c><C-c> ^i// <esc>
vmap <C-c> "+y
imap <C-v> <esc>"+p
nmap <tab> ==
imap <C-s> <esc>:w<cr>

noremap <F3> :call Svndiff("prev")<CR>
noremap <F4> :call Svndiff("next")<CR>
noremap <F5> :call Svndiff("clear")<CR> 


hi DiffAdd      ctermfg=0 ctermbg=2 guibg='green'
hi DiffDelete   ctermfg=0 ctermbg=1 guibg='red'
hi DiffChange   ctermfg=0 ctermbg=3 guibg='yellow' 

set cursorline
highlight CursorLine ctermfg=darkred ctermbg=gray cterm=none

set cursorcolumn
highlight Cursorcolumn ctermfg=darkred ctermbg=lightgray cterm=none
set laststatus=2

"set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\[HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
set statusline=%F%m%r%h%w\ [TYPE=%Y]\ [LEN=%L]


"set guioptions-=m
set guioptions-=T
set guifont=inconsolata\ Bold\ 14


au BufEnter *.sm set ft=c
au BufNewFile,BufRead *.cl set filetype=c

let g:vimgdb_debug_file = ""
run macros/gdb_mappings.vim 

"set fdm=indent
set backspace=indent,eol,start



if has("persistent_undo")
    set undodir='~/.undodir/'
    set undofile
endif

colors spring
colors blacksea 
"set background=dark
let g:indent_guides_start_level = 2
hi IndentGuidesOdd  ctermbg=yellow
hi IndentGuidesEven ctermbg=darkgrey

nmap <f1> :bd<cr>
set ww=<,>,h,l,[,]
inoremap ( ()<ESC>i
inoremap [ []<ESC>i
inoremap { {}<ESC>i
"inoremap < <><ESC>i
inoremap ' ''<ESC>i
inoremap " ""<ESC>i

