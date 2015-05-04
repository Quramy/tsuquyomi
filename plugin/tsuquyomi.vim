"============================================================================
" FILE: tsuquyomi.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

" Preprocessing {{{
if exists('g:loaded_tsuquyomi')
  finish
elseif v:version < 704
  echoerr 'Tsuquyomi does not work this version of Vim "' . v:version . '".'
  finish
endif

let g:loaded_tsuquyomi = 1

let s:save_cpo = &cpo
set cpo&vim
" Preprocessing }}}

" Global options defintion. {{{
let g:tsuquyomi_auto_open =
      \ get(g:, 'tsuquyomi_auto_open', 1)
let g:tsuquyomi_use_dev_node_module =
      \ get(g:, 'tsuquyomi_use_dev_node_module', 0)
let g:tsuquyomi_tsserver_path =
      \ get(g:, 'tsuquyomi_tsserver_path', '')
let g:tsuquyomi_debug = 
      \ get(g:, 'tsuquyomi_debug', 0)
let g:tsuquyomi_tsserver_debug = 
      \ get(g:, 'tsuquyomi_tsserver_debug', 0)
let g:tsuquyomi_nodejs_path = 
      \ get(g:, 'tsuquyomi_nodejs_path', 'node')
let g:tsuquyomi_waittime_after_open= 
      \ get(g:, 'tsuquyomi_waittime_after_open', 0.01)
let g:tsuquyomi_completion_chank_size = 
      \ get(g:, 'tsuquyomi_completion_chank_size', 15)
let g:tsuquyomi_definition_split =
      \ get(g:, 'tsuquyomi_definition_split', 0)
" Global options defintion. }}}

" augroup tsuquyomi_global_command_group
"   autocmd!
" augroup END

" Define commands to operate TSServer
command! TsuquyomiStartServer : call tsuquyomi#startServer()
command! TsuquyomiStatusServer : echom tsuquyomi#statusServer()
command! TsuquyomiStopServer : call tsuquyomi#stopServer()

" Close and re-open all buffers
command! TsuquyomiReloadProject : call tsuquyomi#reloadProject()

let &cpo = s:save_cpo
unlet s:save_cpo
