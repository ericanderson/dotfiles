" Must come first!
set nocompatible

runtime bundle/vim-pathogen/autoload/pathogen.vim
call pathogen#infect()

set history=256
set t_Co=256
set nowritebackup
set nobackup
set ignorecase
set smartcase
set incsearch

" Make Ctrl-u and Ctlr-w undoable
inoremap <c-u> <c-g>u<c-u>
inoremap <c-w> <c-g>u<c-w>


set autoindent
"set cindent

set number

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

color xoria256

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


