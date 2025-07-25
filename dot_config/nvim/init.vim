" Must come first!
set nocompatible

call plug#begin('$HOME/.config/nvim/plugged')
Plug 'mileszs/ack.vim'
Plug 'tomasiser/vim-code-dark'
Plug 'pearofducks/ansible-vim'
Plug 'scrooloose/nerdtree'
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-surround'
Plug 'editorconfig/editorconfig-vim'
Plug 'airblade/vim-gitgutter'
Plug 'itchyny/lightline.vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'scrooloose/nerdcommenter'
Plug 'leafgarland/typescript-vim'

Plug 'junegunn/seoul256.vim'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'

Plug 'Shougo/vimproc.vim', {'do' : 'make'}

Plug 'HerringtonDarkholme/yats.vim'
Plug 'mhartington/nvim-typescript', {'do': './install.sh'}
" Plug 'Quramy/tsuquyomi'
Plug 'jason0x43/vim-js-indent'

if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
let g:deoplete#enable_at_startup = 1
call plug#end()

let g:seoul256_background = 235
colo seoul256


" lightline makes showmode unnecessary
set noshowmode
let g:lightline = { 'colorscheme': 'seoul256' }

" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

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

set backspace=indent,eol,start

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

set wildignore+=*.swp,*.bak,*.class,node_modules/**

set pastetoggle=<F2>

" Lets use hidden buffers
set hidden

" Use sane regex
nnoremap / /\v
vnoremap / /\v

" clear out search
nnoremap <leader><space> :noh<cr>

" Lets get crazy here and disable my arrow keys :/
"nnoremap <up> <nop>
"nnoremap <down> <nop>
"nnoremap <left> <nop>
"nnoremap <right> <nop>
"inoremap <up> <nop>
"inoremap <down> <nop>
"inoremap <left> <nop>
"inoremap <right> <nop>

" Make j and k do the right thing
nnoremap j gj
nnoremap k gk

" Store backups in sane place
set backupdir=$HOME/.vim-tmp,$HOME/.tmp,$HOME/tmp,/var/tmp,/tmp
set directory=$HOME/.vim-tmp,$HOME/.tmp,$HOME/tmp,/var/tmp,/tmp

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

nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

set laststatus=2

" Configure Ruby
autocmd FileType ruby,eruby,yaml set ai sw=2 sts=2 et

" Configure CoffeeScript
au BufNewFile,BufReadPost *.coffee setl ai sts=2 shiftwidth=2 expandtab

" Auto commands
au BufRead,BufNewFile {Vagrantfile,Gemfile,Rakefile,Capfile,*.rake,config.ru}     set ft=ruby
au BufRead,BufNewFile {*.md,*.mkd,*.markdown}                         set ft=markdown
au BufRead,BufNewFile {COMMIT_EDITMSG}                                set ft=gitcommits

autocmd BufWritePre * :%s/\s\+$//e " Remove trailing whitespace


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

" Settings for ansible-vim
let g:ansible_name_highlight = 'd'
let g:ansible_extra_keywords_highlight = 1



autocmd FileType typescript nmap <buffer> <Leader>t : <C-u>echo tsuquyomi#hint()<CR>


augroup typescript
    autocmd!
    " setting typescript things.
    let g:nvim_typescript#type_info_on_hold = 1
    let g:nvim_typescript#signature_complete = 1

    autocmd BufNewFile,BufRead *.ts set filetype=typescript
    autocmd BufNewFile,BufRead *.tsx set filetype=typescript.jsx
    autocmd FileType typescript set tabstop=2 shiftwidth=2 expandtab
    nnoremap <leader>i :TSImport<CR>
    nnoremap <leader>d :TSDefPreview<CR>
    nnoremap <leader>t :TSType<CR>
    nnoremap <leader>f :TSGetCodeFix<CR> " this is called on insert leave
augroup END
