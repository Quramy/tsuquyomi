"============================================================================
" FILE: tsuquyomi.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

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
  map <buffer> <C-[> <Plug>(TsuquyomiReferences)
endif

setlocal omnifunc=tsuquyomi#complete

silent! call tsuquyomi#open()
