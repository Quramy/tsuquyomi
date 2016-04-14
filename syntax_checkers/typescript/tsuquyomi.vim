"============================================================================
" FILE: syntax_checkers/typescript/tsuquyomi.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

" Preprocessing {{{
scriptencoding utf-8
if exists('g:loaded_syntastic_tsuquyomi_syntax_checker')
  finish
endif

let g:loaded_syntastic_tsuquyomi_syntax_checker = 1
let s:save_cpo = &cpo
set cpo&vim
" Preprocessing }}}

function! SyntaxCheckers_typescript_tsuquyomi_IsAvailable() dict abort
  return 1
endfunction

function! SyntaxCheckers_typescript_tsuquyomi_GetLocList() dict abort
  let quickfix_list = tsuquyomi#createFixlist()
  for qf in quickfix_list
    let qf.valid = 1
    let qf.bufnr = bufnr('%')
  endfor
  return quickfix_list
endfunction

call g:SyntasticRegistry.CreateAndRegisterChecker({
      \ 'filetype': 'typescript',
      \ 'name': 'tsuquyomi'
      \ })

let &cpo = s:save_cpo
unlet s:save_cpo
