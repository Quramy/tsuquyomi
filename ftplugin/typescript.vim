"============================================================================
" FILE: tsuquyomi.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:V = vital#of('tsuquyomi')
let s:P = s:V.import('ProcessManager')

if(!exists(g:tsuquyomi_is_available) && !s:P.is_available())
  let g:tsuquyomi_is_available = 0
  echom '[tsuquyomi] Shougo/vimproc.vim is not installed. Please install it.'
  finish
endif
if(!g:tsuquyomi_is_available)
  finish
endif

let g:tsuquyomi_is_available = 1

" ### Buffer local variables {{{
" These variables can be read by autoload/tsuquyomi.vim.
"
let b:tmpfilename = 0   " Where this buffer is flashed.
let b:is_opened = 0     " Whether TSServer opens this buffer.
let b:is_dirty = 0      " Whether the user has changed the buffer's text.

" ### Buffer local variables }}}

command! -buffer TsuquyomiOpen          :call tsuquyomi#open()
command! -buffer TsuquyomiClose         :call tsuquyomi#close()
command! -buffer TsuquyomiReload        :call tsuquyomi#reload()
command! -buffer TsuquyomiDumpCurrent   :call tsuquyomi#dumpCurrent()

command! -buffer TsuquyomiDefinition    :call tsuquyomi#definition()
command! -buffer TsuquyomiReferences    :call tsuquyomi#references()
command! -buffer TsuquyomiGeterr        :call tsuquyomi#geterr()

noremap <silent> <buffer> <Plug>(TsuquyomiDefinition) :TsuquyomiDefinition <CR>
noremap <silent> <buffer> <Plug>(TsuquyomiReferences) :TsuquyomiReferences <CR>

augroup tsuquyomi_defaults
  autocmd!
  autocmd BufNewFile,BufRead *.ts setlocal omnifunc=tsuquyomi#complete
  "autocmd BufWritePost *.ts silent! call tsuquyomi#reload()
  autocmd BufWritePost *.ts silent! call tsuquyomi#reloadAndGeterr()
  autocmd TextChanged,TextChangedI *.ts silent! call tsuquyomi#letDirty()
augroup END

" Default mapping.
if !hasmapto('<Plug>(TsuquyomiDefinition)')
  map <buffer> <C-]> <Plug>(TsuquyomiDefinition)
endif
if !hasmapto('<Plug>(TsuquyomiReferences)')
  map <buffer> <C-^> <Plug>(TsuquyomiReferences)
endif

setlocal bexpr=tsuquyomi#balloonexpr()
setlocal omnifunc=tsuquyomi#complete

if g:tsuquyomi_auto_open
  silent! call tsuquyomi#open()
endif
