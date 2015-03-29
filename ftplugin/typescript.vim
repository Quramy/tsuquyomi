"============================================================================
" FILE: tsuquyomi.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

command! -buffer TSQopen : call tsuquyomi#open()
command! -buffer TSQreload : call tsuquyomi#reload()
command! -buffer TSQdumpCurrent : call tsuquyomi#dumpCurrent()

command! -buffer TSQdefinition : call tsuquyomi#definition()

augroup tsuquyomi_defaults
  autocmd!
  autocmd BufNewFile,BufRead *.ts setlocal omnifunc=tsuquyomi#complete
  autocmd BufWritePost *.ts silent! call tsuquyomi#reload()
  autocmd TextChanged,TextChangedI *.ts silent! call tsuquyomi#letDirty()
augroup END

" TODO refactoring key map
nnoremap <silent> <buffer> <C-]> : TSQdefinition <CR>

setlocal omnifunc=tsuquyomi#complete

silent! call tsuquyomi#open()
