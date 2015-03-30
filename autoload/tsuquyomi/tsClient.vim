"============================================================================
" FILE: tsuquyomi.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:script_dir = expand('<sfile>:p:h')

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

let s:JSON = s:V.import('Web.JSON')
let s:Filepath = s:V.import('System.Filepath')

let s:tsq = 'tsuquyomiTSServer'


" ### Utilites {{{
function! s:error(msg)
  echoerr (a:msg)
endfunction

function! s:waitTss(sec)
  call s:P.read_wait(s:tsq, a:sec, [])
endfunction

function! s:createTssPath()
  if g:tsuquyomi_use_dev_node_module == 0
    let l:cmd = 'tsserver'
  else
    if g:tsuquyomi_use_dev_node_module == 1
      let l:path = s:Filepath.join(s:script_dir, '../../node_modules/typescript/bin/tsserver.js')
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
function! tsuquyomi#tsClient#startTss()
  if s:P.state(s:tsq) == 'existing'
    return 'existing'
  endif
  let l:cmd = substitute(s:createTssPath(), '\\', '\\\\', 'g')
  "echo l:cmd
  let l:is_new = s:P.touch(s:tsq, l:cmd)
  if l:is_new == 'new'
    let [out, err, type] = s:P.read_wait(s:tsq, 0.1, [])
    let st = tsuquyomi#tsClient#statusTss()
    if !g:tsuquyomi_tsserver_debug
      if err != ''
        call s:error('Fail to start TSServer... '.err)
      endif
    endif
  endif
  return l:is_new
endfunction

"
"Terminate TSServer process if it exsits.
function! tsuquyomi#tsClient#stopTss()
  let l:res = s:P.term(s:tsq)
  return l:res
endfunction

function! tsuquyomi#tsClient#statusTss()
  return s:P.state(s:tsq)
endfunction

"
"Write to stdin of tsserver proc, and return stdout.
function! tsuquyomi#tsClient#sendTssStd(line, delay)
  call tsuquyomi#tsClient#startTss()
  call s:P.writeln(s:tsq, a:line)
  let [out, err, type] = s:P.read_wait(s:tsq, a:delay, ['Content-Length: \d\+'])
  echom err
  "echo type
  if type == 'timedout'
    return []
  elseif type == 'matched'
    let l:tmp1 = substitute(out, 'Content-Length: \d\+', '', 'g')
    let l:tmp2 = substitute(l:tmp1, '\r', '', 'g')
    let l:res_list = split(l:tmp2, '\n\+')
    "echo l:res_list
    return l:res_list
  else
    return 'inactive'
  endif
endfunction

"
" Send a command to tsserver.
" PARAM: {String} cmd Command type. e.g. 'open', 'completion', etc...
" PARAM: {Dictionary} args Arguments object. e.g. {'file': 'myApp.ts'}.
" RETURNS: {List<Dictionary>}
function! tsuquyomi#tsClient#sendCommand(cmd, args)
  return tsuquyomi#tsClient#sendCommandWithDelay(a:cmd, a:args, 0.01)
endfunction
"
" Send a command to tsserver and wait.
" PARAM: {String} cmd Command type. e.g. 'open', 'completion', etc...
" PARAM: {Dictionary} args Arguments object. e.g. {'file': 'myApp.ts'}.
" RETURNS: {List<Dictionary>}
function! tsuquyomi#tsClient#sendCommandWithDelay(cmd, args, delay)
  let l:input = s:JSON.encode({'command': a:cmd, 'arguments': a:args})
  let l:stdout_list = tsuquyomi#tsClient#sendTssStd(l:input, a:delay)
  let l:length = len(l:stdout_list)
  if l:length > 0
    "echo 'stdout length: '.l:length
    let l:res_list = []
    for e in l:stdout_list
      call add(l:res_list, s:JSON.decode(e))
    endfor
    return l:res_list
  else
    return []
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
function! tsuquyomi#tsClient#tsOpen(file)
  let l:args = {'file': a:file}
  let l:res = tsuquyomi#tsClient#sendCommand('open', l:args)
  call s:waitTss(g:tsuquyomi_waittime_after_open)
  return l:res
endfunction

" Send close command to TSServer.
" This command does not return any response.
function! tsuquyomi#tsClient#tsClose(file)
  let l:args = {'file': a:file}
  return tsuquyomi#tsClient#sendCommand('close', l:args)
endfunction

" Save an opened file to tmpfile.
" This function can be called for only debugging.
" This command does not return any response.
function! tsuquyomi#tsClient#tsSaveto(file, tmpfile)
  let l:args = {'file': a:file, 'tmpfile': a:tmpfile}
  return tsuquyomi#tsClient#sendCommand('saveto', l:args)
endfunction

" Fetch keywards to complete from TSServer.
" PARAM: {string} file File name.
" PARAM: {string} line The line number of location to complete.
" PARAM: {string} offset The col number of location to complete.
" PARAM: {string} prefix Prefix to filter result set.
" RETURNS: {list} A List of completion info Dictionary.
"   e.g. :
"     [
"       {'name': 'close', 'kindModifiers': 'declare', 'kind': 'function'},
"       {'name': 'clipboardData', 'kindModifiers': 'declare', 'kind': 'var'}
"     ]
function! tsuquyomi#tsClient#tsCompletions(file, line, offset, prefix)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'prefix': a:prefix}
  let l:result = tsuquyomi#tsClient#sendCommand('completions', l:args)
  if(len(l:result) == 1)
    let l:info = l:result[0]
    if(has_key(l:info, 'body'))
      return l:info.body
    else
      return []
    endif
  else
    "TODO
  endif
endfunction

" Emmit to change file to TSServer.
" Param: {string} file File name to change.
" Param: {int} line The line number of starting point of range to change.
" Param: {int} offset The col number of starting point of range to change.
" Param: {int} endLine The line number of end point of range to change.
" Param: {int} endOffset The col number of end point of range to change.
" Param: {string} insertString String after replacing 
" This command does not return any response.
function! tsuquyomi#tsClient#tsChange(file, line, offset, endLine, endOffset, insertString)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'endLine': a:endLine, 'endOffset': a:endOffset, 'insertString': a:insertString}
  return tsuquyomi#tsClient#sendCommand('change', l:args)
endfunction

" CompletionDetails = "completionEntryDetails";
function! tsuquyomi#tsClient#tsCompletionEntryDetails(file, line, offset, entryNames)
  call s:error('not implemented!')
endfunction

" Configure = "configure";
function! tsuquyomi#tsClient#tsConfigure(file, tabSize, indentSize, hostInfo)
  call s:error('not implemented!')
endfunction

" Fetch location where the symbol at cursor(line, offset) in file is defined.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of location to complete.
" PARAM: {int} offset The col number of location to complete.
" RETURNS: {list} A list of dictionaries of definition location.
" e.g. : 
" [{'file': 'hogehoge.ts', 'start': {'line': 3, 'offset': 2}, 'end': {'line': 3, 'offset': 10}}]
"   
function! tsuquyomi#tsClient#tsDefinition(file, line, offset)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset}
  let l:result = tsuquyomi#tsClient#sendCommand('definition', l:args)
  if(len(l:result) == 1)
    let l:info = l:result[0]
    if(has_key(l:info, 'body'))
      return l:info.body
    else
      return []
    endif
  else
    "TODO
  endif
  return l:result
endfunction

" Format = "format";
function! tsuquyomi#tsClient#tsFormat(file, line, offset, endLine, endOffset)
  call s:error('not implemented!')
endfunction

" Formatonkey = "formatonkey";
function! tsuquyomi#tsClient#tsFormationkey(file, line, offset, key)
  call s:error('not implemented!')
endfunction

" Geterr = "geterr";
" PARAM: {int} delay Delay time [msec].
function! tsuquyomi#tsClient#tsGeterr(files, delay)
  let l:args = {'files': a:files, 'delay': a:delay}
  let l:delaySec = a:delay * 1.0 / 1000.0
  let l:result = tsuquyomi#tsClient#sendCommandWithDelay('geterr', l:args, l:delaySec)
  if(len(l:result) > 0)
    let l:bodies = {}
    for res in l:result
      if(has_key(res, 'body') && has_key(res, 'event'))
        let l:bodies[res.event] = res.body
      endif
    endfor
    return l:bodies
  else
    return {}
  endif
endfunction

" NavBar = "navbar";
function! tsuquyomi#tsClient#tsNavBar(file)
  call s:error('not implemented!')
endfunction

" Navto = "navto";
function! tsuquyomi#tsClient#tsNavto(file, searchValue, maxResultCount)
  call s:error('not implemented!')
endfunction

" Quickinfo = "quickinfo";
function! tsuquyomi#tsClient#tsQuickinfo(file, line, offset)
  call s:error('not implemented!')
endfunction

" Fetch a list of references.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of the symbol's position.
" PARAM: {int} offset The col number of the symbol's position.
" RETURNS: {dictionary} Reference information.
" e.g:
" {
"   'symbolName': 'SomeClass',
"   'symbolDisplayString': 'SomeModule.SomeClass',
"   'refs': [
"     {
"       'file': 'SomeClass.ts', 'isWriteAccess': 1, 
"       'start': {'line': 3', 'offset': 2}, 'end': {'line': 3, 'offset': 20},
"       'lineText': 'export class SomeClass {'
"     }, {
"       'file': 'OtherClass.ts', 'isWriteAccess': 0, 
"       'start': {'line': 5', 'offset': 2}, 'end': {'line': 5, 'offset': 20},
"       'lineText': 'export class OtherClass extends SomeClass{'
"     }
"   ]
" }
function! tsuquyomi#tsClient#tsReferences(file, line, offset)
  let l:arg = {'file': a:file, 'line': a:line, 'offset': a:offset}
  let l:result = tsuquyomi#tsClient#sendCommand('references', l:arg)
  if(len(l:result) == 1)
    let l:info = l:result[0]
    if(has_key(l:info, 'body'))
      return l:info.body
    else
      return {}
    endif
  else
    return {}
  endif
endfunction

" Reload an opend file.
" It can be used for telling change of buffer to TSServer.
" PARAM: {string} file File name 
" PARAM: {string} tmpfile
" RETURNS: {0|1} 
function! tsuquyomi#tsClient#tsReload(file, tmpfile)
  let l:arg = {'file': a:file, 'tmpfile': a:tmpfile}
  let l:result = tsuquyomi#tsClient#sendCommand('reload', l:arg)
  if(len(l:result) == 1)
    if(has_key(l:result[0], 'success'))
      return l:result[0].success
    else
      return 0
    endif
  else
    return 0
  endif
endfunction

" Rename = "rename";
function! tsuquyomi#tsClient#tsRename(file, line, offset, findInComments, findInString)
  call s:error('not implemented!')
endfunction

" Find brace matching pair.
" Vim has brace matching natively, so I don't implement this method.
function! tsuquyomi#tsClient#tsBrace(file, line, offset)
  call s:error('not implemented!')
endfunction

" ### TSServer command wrappers }}}


let &cpo = s:save_cpo
unlet s:save_cpo
