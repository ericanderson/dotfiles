" Must come first!
set nocompatible

runtime bundle/vim-pathogen/autoload/pathogen.vim
call pathogen#infect()

set title
set history=256
set t_Co=256
set nowritebackup
set nobackup
set ignorecase
set smartcase
set incsearch

set encoding=utf-8
set wildmenu
set wildmode=list:longest

set smarttab

" Highlight search terms
set hlsearch
set incsearch

set ruler

let mapleader=","

nmap <silent> <leader>n :silent :nohlsearch

" Make Ctrl-u and Ctlr-w undoable
inoremap <c-u> <c-g>u<c-u>
inoremap <c-w> <c-g>u<c-w>

set scrolloff=3 " Makes scrolling off screen show 3 lines

set wildignore=*.swp,*.bak,*.class

set pastetoggle=<F2>

" Lets use hidden buffers
set hidden

" Use sane regex
nnoremap / /\v
vnoremap / /\v

" clear out search
nnoremap <leader><space> :noh<cr>

" Lets get crazy here and disable my arrow keys :/
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
nnoremap j gj
nnoremap k gk

" Store backups in sane place
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp

set autoindent
"set cindent

set number

" Lets do some cool leader stuff
nnoremap <leader>W :%s/\s\+$//<cr>:let @/=''<CR>

" Attempting to use jj to get back to normal mode
inoremap jj <ESC>

syntax on
filetype plugin indent on

set splitbelow
set splitright
set laststatus=2

" Configure Ruby
autocmd FileType ruby,eruby,yaml set ai sw=2 sts=2 et

" Configure CoffeeScript
au BufNewFile,BufReadPost *.coffee setl ai sts=2 shiftwidth=2 expandtab

" Auto commands
au BufRead,BufNewFile {Vagrantfile,Gemfile,Rakefile,Capfile,*.rake,config.ru}     set ft=ruby
au BufRead,BufNewFile {*.md,*.mkd,*.markdown}                         set ft=markdown
au BufRead,BufNewFile {COMMIT_EDITMSG}                                set ft=gitcommit

autocmd BufWritePre * :%s/\s\+$//e " Remove trailing whitespace

color twilight256

" NERDTree
function! NERDTreeQuit()
  redir => buffersoutput
  silent buffers
  redir END
"                     1BufNo  2Mods.     3File           4LineNo
  let pattern = '^\s*\(\d\+\)\(.....\) "\(.*\)"\s\+line \(\d\+\)$'
  let windowfound = 0

  for bline in split(buffersoutput, "\n")
    let m = matchlist(bline, pattern)

    if (len(m) > 0)
      if (m[2] =~ '..a..')
        let windowfound = 1
      endif
    endif
  endfor

  if (!windowfound)
    quitall
  endif
endfunction
autocmd WinEnter * call NERDTreeQuit()


