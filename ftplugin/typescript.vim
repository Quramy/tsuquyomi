"============================================================================
" FILE: tsuquyomi.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

if !tsuquyomi#config#preconfig()
  finish
endif

if(!exists('g:tsuquyomi_is_available'))
  let g:tsuquyomi_is_available = 0
  echom '[Tsuquyomi] Shougo/vimproc.vim is not installed. Please install it.'
  finish
endif
if(!g:tsuquyomi_is_available)
  finish
endif

let g:tsuquyomi_is_available = 1

command! -buffer -nargs=* -complete=buffer TsuquyomiOpen    :call tsuquyomi#open(<f-args>)
command! -buffer -nargs=* -complete=buffer TsuOpen          :call tsuquyomi#open(<f-args>)
command! -buffer -nargs=* -complete=buffer TsuquyomiClose   :call tsuquyomi#close(<f-args>)
command! -buffer -nargs=* -complete=buffer TsuClose         :call tsuquyomi#close(<f-args>)
command! -buffer -nargs=* -complete=buffer TsuquyomiReload  :call tsuquyomi#reload(<f-args>)
command! -buffer -nargs=* -complete=buffer TsuReload        :call tsuquyomi#reload(<f-args>)
command! -buffer -nargs=* -complete=buffer TsuquyomiDump    :call tsuquyomi#dump(<f-args>)
command! -buffer -nargs=* -complete=buffer TsuDump          :call tsuquyomi#dump(<f-args>)
command! -buffer -nargs=1 TsuquyomiSearch                   :call tsuquyomi#navtoByLoclistContain(<f-args>)
command! -buffer -nargs=1 TsuSearch                         :call tsuquyomi#navtoByLoclistContain(<f-args>)

command! -buffer TsuquyomiDefinition     :call tsuquyomi#definition()
command! -buffer TsuDefinition           :call tsuquyomi#definition()
command! -buffer TsuquyomiGoBack         :call tsuquyomi#goBack()
command! -buffer TsuGoBack               :call tsuquyomi#goBack()
command! -buffer TsuquyomiReferences     :call tsuquyomi#references()
command! -buffer TsuReferences           :call tsuquyomi#references()
command! -buffer TsuquyomiGeterr         :call tsuquyomi#geterr()
command! -buffer TsuGeterr               :call tsuquyomi#geterr()
command! -buffer TsuquyomiGeterrProject  :call tsuquyomi#geterrProject()
command! -buffer TsuGeterrProject        :call tsuquyomi#geterrProject()
command! -buffer TsuquyomiRenameSymbol   :call tsuquyomi#renameSymbol()
command! -buffer TsuRenameSymbol         :call tsuquyomi#renameSymbol()
command! -buffer TsuquyomiRenameSymbolC  :call tsuquyomi#renameSymbolWithComments()
command! -buffer TsuRenameSymbolC        :call tsuquyomi#renameSymbolWithComments()

" TODO These commands don't work correctly.
command! -buffer TsuquyomiRenameSymbolS  :call tsuquyomi#renameSymbolWithStrings()
command! -buffer TsuRenameSymbolS        :call tsuquyomi#renameSymbolWithStrings()
command! -buffer TsuquyomiRenameSymbolCS :call tsuquyomi#renameSymbolWithCommentsStrings()
command! -buffer TsuRenameSymbolCS       :call tsuquyomi#renameSymbolWithCommentsStrings()

command! -buffer TsuquyomiImport         :call tsuquyomi#es6import#complete()
command! -buffer TsuImport               :call tsuquyomi#es6import#complete()

noremap <silent> <buffer> <Plug>(TsuquyomiDefinition)     :TsuquyomiDefinition <CR>
noremap <silent> <buffer> <Plug>(TsuquyomiGoBack)         :TsuquyomiGoBack <CR>
noremap <silent> <buffer> <Plug>(TsuquyomiReferences)     :TsuquyomiReferences <CR>
noremap <silent> <buffer> <Plug>(TsuquyomiRenameSymbol)   :TsuquyomiRenameSymbol <CR>
noremap <silent> <buffer> <Plug>(TsuquyomiRenameSymbolC)  :TsuquyomiRenameSymbolC <CR>
noremap <silent> <buffer> <Plug>(TsuquyomiImport)         :TsuquyomiImport <CR>

" TODO These commands don't work correctly.
noremap <silent> <buffer> <Plug>(TsuquyomiRenameSymbolS)  :TsuquyomiRenameSymbolS <CR>
noremap <silent> <buffer> <Plug>(TsuquyomiRenameSymbolCS) :TsuquyomiRenameSymbolCS <CR>

" Default mapping.
if(!exists('g:tsuquyomi_disable_default_mappings'))
  if !hasmapto('<Plug>(TsuquyomiDefinition)')
      map <buffer> <C-]> <Plug>(TsuquyomiDefinition)
  endif
  if !hasmapto('<Plug>(TsuquyomiGoBack)')
      map <buffer> <C-t> <Plug>(TsuquyomiGoBack)
  endif
  if !hasmapto('<Plug>(TsuquyomiReferences)')
      map <buffer> <C-^> <Plug>(TsuquyomiReferences)
  endif
endif

setlocal omnifunc=tsuquyomi#complete

if exists('+bexpr')
  setlocal bexpr=tsuquyomi#balloonexpr()
endif

if !g:tsuquyomi_disable_quickfix
  augroup tsuquyomi_geterr
    autocmd!
    autocmd BufWritePost *.ts,*.tsx silent! call tsuquyomi#reloadAndGeterr()
  augroup END
endif

augroup tsuquyomi_defaults
  autocmd!
  autocmd BufWinEnter * silent! call tsuquyomi#setPreviewOption()
  autocmd TextChanged,TextChangedI *.ts,*.tsx silent! call tsuquyomi#letDirty()
augroup END

if g:tsuquyomi_auto_open
  silent! call tsuquyomi#open()
endif
