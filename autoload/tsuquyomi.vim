scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:script_dir = expand('<sfile>:p:h')

" ## Global variables {{{
let g:tsuquyomi_tsserver_path=''
let g:tsuquyomi_nodejs_path='node'
"let g:tsuquyomi_use_dev_node_module=0
" ## Global variables }}}

let s:V = vital#of('tsuquyomi')
let s:P = s:V.import('ProcessManager')
let s:JSON = s:V.import('Web.JSON')
let s:Filepath = s:V.import('System.Filepath')

let s:tsq = 'tsuquyomiTSServer'



" ### Utilites {{{
function! s:error(msg)
  echom (a:msg)
  throw 'tsuquyomi: '.a:msg
endfunction

function! s:createTssPath()
  if g:tsuquyomi_use_dev_node_module == 0
    let l:cmd = 'tsserver'
  else
    if g:tsuquyomi_use_dev_node_module == 1
      let l:path = s:Filepath.join(s:script_dir, '../node_modules/typescript/bin/tsserver.js')
    elseif g:tsuquyomi_use_dev_node_module == 2
      let l:path = g:tsuquyomi_tsserver_path
    else
      call s:error('Invalid option value "g:tsuquyomi_use_dev_node_module".')
    endif
    if filereadable(l:path) != 1
      call s:error('TSServer script does not exist. Try "npm install"., '.l:path)
    endif
    let l:cmd = g:tsuquyomi_nodejs_path.' "'.l:path.'"'
  endif
  return l:cmd
endfunction

" ### Utilites }}}

" ### Core Functions {{{
"
" If not exsiting process of TSServer, create it.
function! tsuquyomi#startTss()
  if s:P.state(s:tsq) == 'existing'
    return 'existing'
  endif
  let l:cmd = substitute(s:createTssPath(), '\\', '\\\\', 'g')
  "echo l:cmd
  let l:is_new = s:P.touch(s:tsq, l:cmd)
  if l:is_new == 'new'
    let [out, err, type] = s:P.read_wait(s:tsq, 0.1, [])
    let st = tsuquyomi#statusTss()
    if err != ''
      call s:error('Fail to start TSserver... '.err)
    endif
  endif
  return l:is_new
endfunction

"
"Terminate TSServer process if it exsits.
function! tsuquyomi#stopTss()
  let l:res = s:P.term(s:tsq)
  return l:res
endfunction

function! tsuquyomi#statusTss()
  return s:P.state(s:tsq)
endfunction

"
"Write to stdin of tsserver proc, and return stdout.
function! tsuquyomi#sendTssStd(line)
  call tsuquyomi#startTss()
  call s:P.writeln(s:tsq, a:line)
  let [out, err, type] = s:P.read(s:tsq, ['Content-Length: \d\+'])
  "echo type
  if type == 'timedout'
    return ''
  elseif type == 'matched'
    return substitute(out, '\r', '', 'g')
  else
    return 'inactive'
  endif
endfunction

"
" Send a command to tsserver.
" @param {String} cmd Command type. e.g. 'open', 'completion', etc...
" @param {Dictionary} args Arguments object. e.g. {'file': 'myApp.ts'}.
function! tsuquyomi#sendCommand(cmd, args)
  let l:input = s:JSON.encode({'command': a:cmd, 'arguments': a:args})
  let l:stdout = tsuquyomi#sendTssStd(l:input)
  if l:stdout != ''
    return s:JSON.decode(l:stdout)
  else
    return {}
  endif
endfunction

"
" ### Core Functions }}}

" ### TSServer command wrappers {{{
"
" There are client's methods of TSServer.
" If you want to know details of APIs, see 'typescript/src/server/protocol.d.ts'.

"
" Send oepn command to TSServer.
" This command does not return any response.
function! tsuquyomi#tsOpen(file)
  let l:args = {'file': a:file}
  return tsuquyomi#sendCommand('open', l:args)
endfunction

" ### TSServer command wrappers }}}


let &cpo  = s:save_cpo
unlet s:save_cpo
