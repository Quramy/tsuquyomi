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
let g:tsuquyomi_use_local_typescript =
      \ get(g:, 'tsuquyomi_use_local_typescript', 1)
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
let g:tsuquyomi_waittime_after_open = 
      \ get(g:, 'tsuquyomi_waittime_after_open', str2float("0.01"))
let g:tsuquyomi_completion_chunk_size = 
      \ get(g:, 'tsuquyomi_completion_chunk_size', 20)
let g:tsuquyomi_completion_detail = 
      \ get(g:, 'tsuquyomi_completion_detail', 0)
let g:tsuquyomi_completion_case_sensitive = 
      \ get(g:, 'tsuquyomi_completion_case_sensitive', 0)
let g:tsuquyomi_case_sensitive_imports =
      \ get(g:, 'tsuquyomi_case_sensitive_imports', 0)
let g:tsuquyomi_completion_preview = 
      \ get(g:, 'tsuquyomi_completion_preview', 0)
let g:tsuquyomi_definition_split =
      \ get(g:, 'tsuquyomi_definition_split', 0)
let g:tsuquyomi_disable_quickfix =
      \ get(g:, 'tsuquyomi_disable_quickfix', 0)
let g:tsuquyomi_save_onrename =
      \ get(g:, 'tsuquyomi_save_onrename', 0)
let g:tsuquyomi_single_quote_import =
      \ get(g:, 'tsuquyomi_single_quote_import', 0)
let g:tsuquyomi_semicolon_import =
      \ get(g:, 'tsuquyomi_semicolon_import', 1)
let g:tsuquyomi_import_curly_spacing =
      \ get(g:, 'tsuquyomi_import_curly_spacing', 1)
let g:tsuquyomi_javascript_support =
      \ get(g:, 'tsuquyomi_javascript_support', 0)
let g:tsuquyomi_ignore_missing_modules =
      \ get(g:, 'tsuquyomi_ignore_missing_modules', 0)
let g:tsuquyomi_shortest_import_path = 
      \ get(g:, 'tsuquyomi_shortest_import_path', 0)
let g:tsuquyomi_baseurl_import_path = 
      \ get(g:, 'tsuquyomi_baseurl_import_path', 0)
let g:tsuquyomi_use_vimproc =
      \ get(g:, 'tsuquyomi_use_vimproc', 0)
let g:tsuquyomi_locale =
      \ get(g:, 'tsuquyomi_locale', 'en')
let g:tsuquyomi_search_term_min_length =
      \ get(g:, 'tsuquyomi_search_term_min_length', 3)
" Global options defintion. }}}

" augroup tsuquyomi_global_command_group
"   autocmd!
" augroup END

" Define commands to operate TSServer
command! TsuquyomiStartServer  : call tsuquyomi#startServer()
command! TsuStartServer        : call tsuquyomi#startServer()
command! TsuquyomiStatusServer : echom tsuquyomi#statusServer()
command! TsuStatusServer       : echom tsuquyomi#statusServer()
command! TsuquyomiStopServer   : call tsuquyomi#stopServer()
command! TsuStopServer         : call tsuquyomi#stopServer()

" Close and re-open all buffers
command! TsuquyomiReloadProject : call tsuquyomi#reloadProject()
command! TsuReloadProject       : call tsuquyomi#reloadProject()

let &cpo = s:save_cpo
unlet s:save_cpo
