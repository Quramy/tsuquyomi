"============================================================================
" FILE: config.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================
"
scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('tsuquyomi')
let s:P = s:V.import('ProcessManager')
let s:Process = s:V.import('Process')
let s:Prelude = s:V.import('Prelude')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = expand('<sfile>:p:h')

let s:tss_cmd = ''
let s:tss_version = {'is_valid': 0, 'out': '???'} 

function! tsuquyomi#config#preconfig()

  if !exists('g:tsuquyomi_is_available')
    if !s:P.is_available()
      " 1. vimproc installation check
      let g:tsuquyomi_is_available = 0
      call s:deleteCommand()
      echom '[Tsuquyomi] Shougo/vimproc.vim is not installed. Please install it.'
      return 0
    else
      " 2. tsserver installation check
      let s:tss_cmd = tsuquyomi#config#tsscmd()
      if s:tss_cmd == ''
        let g:tsuquyomi_is_available = 0
        call s:deleteCommand()
        return 0
      endif

      " 3. TypeScript version check
      call tsuquyomi#config#getVersion()
      if !s:tss_version.is_valid
        let g:tsuquyomi_is_available = 0
        call s:deleteCommand()
        echom '[Tsuquyomi] Your TypeScript version is invalid. '.s:tss_version.out
        return 0
      endif
      if !tsuquyomi#config#isHigher(150)
        let g:tsuquyomi_is_available = 0
        call s:deleteCommand()
        echom '[Tsuquyomi] tsuquyomi requires typescript@~1.5.0'
        return 0
      endif
      let g:tsuquyomi_is_available = 1
    endif
  endif

  return g:tsuquyomi_is_available
endfunction

function! s:deleteCommand()
  delc TsuquyomiStartServer
  delc TsuStartServer
  delc TsuquyomiStopServer
  delc TsuStopServer
  delc TsuquyomiStatusServer
  delc TsuStatusServer
  delc TsuquyomiReloadProject
  delc TsuReloadProject
endfunction

function! tsuquyomi#config#tsscmd()
  if s:tss_cmd !=# ''
    return s:tss_cmd
  endif
  if g:tsuquyomi_use_local_typescript != 0
    let l:prj_dir = s:Prelude.path2project_directory(getcwd(), 1)
    if l:prj_dir !=# ''
      let l:searched_tsserver_path = s:Filepath.join(l:prj_dir, 'node_modules/typescript/bin/tsserver')
      if filereadable(l:searched_tsserver_path)
        return g:tsuquyomi_nodejs_path.' "'.l:searched_tsserver_path.'"'
      endif
    endif
  endif
  if g:tsuquyomi_use_dev_node_module == 0
    let l:cmd = 'tsserver'
    if !executable(l:cmd)
      echom '[Tsuquyomi] tsserver is not installed. Try "npm -g install typescript".'
      return ''
    endif
  else
    if g:tsuquyomi_use_dev_node_module == 1
      let l:path = s:Filepath.join(s:script_dir, '../../node_modules/typescript/bin/tsserver')
    elseif g:tsuquyomi_use_dev_node_module == 2
      let l:path = g:tsuquyomi_tsserver_path
    else
      echom '[Tsuquyomi] Invalid option value "g:tsuquyomi_use_dev_node_module".'
      return ''
    endif
    if filereadable(l:path) != 1
      echom '[Tsuquyomi] tsserver.js does not exist. Try "npm install"., '.l:path
      return ''
    endif
    let l:cmd = g:tsuquyomi_nodejs_path.' "'.l:path.'"'
  endif
  return l:cmd
endfunction

function! tsuquyomi#config#getVersion()
  if s:tss_version.is_valid
    return s:tss_version
  endif
  let l:cmd = substitute(tsuquyomi#config#tsscmd(), 'tsserver', 'tsc', '')
  let out = s:Process.system(l:cmd.' --version')
  let pattern = '\vVersion\s+(\d+)\.(\d+)\.(\d+)-?([^\.\n\s]*)'
  let matched = matchlist(out, pattern)
  if !len(matched)
    let s:tss_version = {'is_valid': 0, 'out': out}
    return s:tss_version
  endif
  let [major, minor, patch] = [str2nr(matched[1]), str2nr(matched[2]), str2nr(matched[3])]
  let s:tss_version = {
        \ 'is_valid': 1,
        \ 'major': major, 'minor': minor, 'patch': patch,
        \ 'channel': matched[4],
        \ }
  return s:tss_version
endfunction

function! tsuquyomi#config#isHigher(target)
  if !s:tss_version.is_valid
    return 0
  endif
  let numeric_version = s:tss_version.major * 100 + s:tss_version.minor * 10 + s:tss_version.patch
  return numeric_version >= a:target
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
