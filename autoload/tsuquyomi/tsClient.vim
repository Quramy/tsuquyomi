"============================================================================
" FILE: tsuquyomi.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if !tsuquyomi#config#preconfig()
  finish
endif

let s:script_dir = expand('<sfile>:p:h')

let s:V = vital#of('tsuquyomi')
let s:P = s:V.import('ProcessManager')
let s:JSON = s:V.import('Web.JSON')
let s:Filepath = s:V.import('System.Filepath')
let s:tsq = 'tsuquyomiTSServer'

let s:request_seq = 0

" ### Utilites {{{
function! s:error(msg)
  echoerr (a:msg)
endfunction

function! s:waitTss(sec)
  call s:P.read_wait(s:tsq, a:sec, [])
endfunction

function! s:debugLog(msg)
  if g:tsuquyomi_debug
    echom a:msg
  endif
endfunction

" ### Utilites }}}

" ### Core Functions {{{
"
" If not exsiting process of TSServer, create it.
function! tsuquyomi#tsClient#startTss()
  if s:P.state(s:tsq) == 'existing'
    return 'existing'
  endif
  let l:cmd = substitute(tsuquyomi#config#tsscmd(), '\\', '\\\\', 'g')
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
  if tsuquyomi#tsClient#statusTss() != 'undefined'
    let l:res = s:P.term(s:tsq)
    return l:res
  endif
endfunction

function! tsuquyomi#tsClient#statusTss()
  return s:P.state(s:tsq)
endfunction

"
"Write to stdin of tsserver proc, and return stdout.
"
" PARAM: {string} line Stdin input.
" PARAM: {float} delay Wait time(sec) after request, until response.
" PARAM: {int} retry_count Retry count.
" PARAM: {int} response_length The number of JSONs contained by this response.
" RETURNS: {list<string>} A list of response string (content-type=json).
function! tsuquyomi#tsClient#sendRequest(line, delay, retry_count, response_length)
  "call s:debugLog('called! '.a:line)
  call tsuquyomi#tsClient#startTss()
  call s:P.writeln(s:tsq, a:line)

  let l:retry = 0
  let response_list = []

  while len(response_list) < a:response_length
    let [out, err, type] = s:P.read_wait(s:tsq, a:delay, ['Content-Length: \d\+'])
    call s:debugLog('out: '.out.', type:'.type)
    if type == 'timedout'
      let retry_delay = 0.05
      while l:retry < a:retry_count
        let [out, err, type] = s:P.read_wait(s:tsq, retry_delay, ['Content-Length: \d\+'])
        if type == 'matched'
          "call s:debugLog('retry: '.l:retry.', length: '.len(response_list))
          break
        endif
        let l:retry = l:retry + 1
      endwhile
    endif

    if type == 'matched'
      let l:tmp1 = substitute(out, 'Content-Length: \d\+', '', 'g')
      let l:tmp2 = substitute(l:tmp1, '\r', '', 'g')
      let l:res_list = split(l:tmp2, '\n\+')
      for res_item in l:res_list
        call add(response_list, res_item)
      endfor
    else
      echom '[Tsuquyomi] TSServer request was timeout:'.a:line
      return response_list
    endif

  endwhile
  "call s:debugLog(a:response_length.', '.len(response_list))
  return response_list
endfunction

"
" Send a command to TSServer.
" This function is called pseudo synchronously.
" PARAM: {string} cmd Command type. e.g. 'completion', etc...
" PARAM: {dictionary} args Arguments object. e.g. {'file': 'myApp.ts'}.
" RETURNS: {list<dictionary>}
function! tsuquyomi#tsClient#sendCommandSyncResponse(cmd, args)
  let l:input = s:JSON.encode({'command': a:cmd, 'arguments': a:args, 'type': 'request', 'seq': s:request_seq})
  let l:stdout_list = tsuquyomi#tsClient#sendRequest(l:input, 0.01, 10, 1)
  let l:length = len(l:stdout_list)
  if l:length == 1
    let res = s:JSON.decode(l:stdout_list[0])
    "if res.success == 0
    "  echom '[Tsuquyomi] TSServer command fail. command: '.res.command.', message: '.res.message
    "endif
    let s:request_seq = s:request_seq + 1
    return [res]
  else
    return []
  endif
endfunction

function! tsuquyomi#tsClient#sendCommandSyncEvents(cmd, args, delay, length)
  let l:input = s:JSON.encode({'command': a:cmd, 'arguments': a:args, 'type': 'request', 'seq': s:request_seq})
  let l:stdout_list = tsuquyomi#tsClient#sendRequest(l:input, a:delay, 2000, a:length)
  "echo l:stdout_list
  let l:length = len(l:stdout_list)
  let l:result_list = []
  if l:length > 0
    for out_str in l:stdout_list
      let res = s:JSON.decode(out_str)
      if res.type != 'event'
        "echom '[Tsuquyomi] TSServer return invalid response: '.out_str
      else
        call add(l:result_list, res)
      endif
    endfor
    let s:request_seq = s:request_seq + 1
    return l:result_list
  else
    return []
  endif

endfunction

function! tsuquyomi#tsClient#sendCommandOneWay(cmd, args)
  let l:input = s:JSON.encode({'command': a:cmd, 'arguments': a:args, 'type': 'request', 'seq': s:request_seq})
  call tsuquyomi#tsClient#sendRequest(l:input, 0.01, 0, 0)
  return []
endfunction

function! tsuquyomi#tsClient#getResponseBodyAsList(responses)
  if len(a:responses) != 1
    return []
  endif
  let response = a:responses[0]
  if has_key(response, 'success') && response.success && has_key(response, 'body')
    return response.body
  else
    return []
  endif
endfunction

function! tsuquyomi#tsClient#getResponseBodyAsDict(responses)
  if len(a:responses) != 1
    return {}
  endif
  let response = a:responses[0]
  if has_key(response, 'success') && response.success && has_key(response, 'body')
    return response.body
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
function! tsuquyomi#tsClient#tsOpen(file)
  let l:args = {'file': a:file}
  call tsuquyomi#tsClient#sendCommandOneWay('open', l:args)
endfunction

" Send close command to TSServer.
" This command does not return any response.
function! tsuquyomi#tsClient#tsClose(file)
  let l:args = {'file': a:file}
  return tsuquyomi#tsClient#sendCommandOneWay('close', l:args)
endfunction

" Save an opened file to tmpfile.
" This function can be called for only debugging.
" This command does not return any response.
function! tsuquyomi#tsClient#tsSaveto(file, tmpfile)
  let l:args = {'file': a:file, 'tmpfile': a:tmpfile}
  return tsuquyomi#tsClient#sendCommandOneWay('saveto', l:args)
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
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('completions', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsList(l:result)
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
  return tsuquyomi#tsClient#sendCommandOneWay('change', l:args)
endfunction

" Fetch details of completion from TSServer.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of location to complete.
" PARAM: {int} offset The col number of location to complete.
" PARAM: {list<string>} entryNames A list of names. These names may be fetched by tsuquyomi#tsClient#tsCompletions function.
" RETURNS: {list} A list of details.
"   e.g. :
"     [{
"       'name': 'DOMError',
"       'kind': 'var',
"       'kindModifier': 'declare',
"       'displayParts': [
"         {'kind': 'keyword', 'text': 'interface'},
"         {'kind': 'space', 'text': ' '},
"         ...
"         {'kind': 'lineBreak', 'text': '\n'},
"         ...
"       ]
"     }, ...]
function! tsuquyomi#tsClient#tsCompletionEntryDetails(file, line, offset, entryNames)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'entryNames': a:entryNames}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('completionEntryDetails', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsList(l:result)
endfunction

"Fetch method signature information from TSServer.
function! tsuquyomi#tsClient#tsSignatureHelp(file, line, offset)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('signatureHelp', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsDict(l:result)
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
"   e.g. : 
"     [{'file': 'hogehoge.ts', 'start': {'line': 3, 'offset': 2}, 'end': {'line': 3, 'offset': 10}}]
function! tsuquyomi#tsClient#tsDefinition(file, line, offset)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('definition', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsList(l:result)
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
  let l:result = tsuquyomi#tsClient#sendCommandSyncEvents('geterr', l:args, l:delaySec, 2)
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

" Fetch navigation list from TSServer.
" PARAM: {string} file File name.
" RETURNS: {list<dict>} Navigation info
"   e.g. :
"     [{
"       'text': 'ModName',
"       'kind': 'module',
"       'kindModifiers: '',
"       'spans': [{
"         'start': {'line': 1, 'offset': 5},
"         'end': {'line': 1, 'offset': 12},
"       }],
"       childItems: [
"         ...   " REMAKS: childItems contains a recursive structure.
"       ]
"     }]
function! tsuquyomi#tsClient#tsNavBar(file)
  let l:args = {'file': a:file}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('navbar', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsList(l:result)
endfunction

" Navto = "navto";
function! tsuquyomi#tsClient#tsNavto(file, searchValue, maxResultCount)
  call s:error('not implemented!')
endfunction

" Fetch quickinfo from TSServer.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of the symbol's position.
" PARAM: {int} offset The col number of the symbol's position.
" RETURNS:  {dict}  
"   e.g. :
"     {
"       'kind': 'method',
"       'kindModifiers': '',
"       'displayString': '(method) SimpleModule.MyClass.say(): string',
"       'start': {'line': 2, 'offset': 2},
"       'start': {'line': 2, 'offset': 9}
"     }
function! tsuquyomi#tsClient#tsQuickinfo(file, line, offset)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('quickinfo', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsDict(l:result)
endfunction

" Fetch a list of references.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of the symbol's position.
" PARAM: {int} offset The col number of the symbol's position.
" RETURNS: {dictionary} Reference information.
"   e.g. :
"     {
"       'symbolName': 'SomeClass',
"       'symbolDisplayString': 'SomeModule.SomeClass',
"       'refs': [
"         {
"           'file': 'SomeClass.ts', 'isWriteAccess': 1, 
"           'start': {'line': 3', 'offset': 2}, 'end': {'line': 3, 'offset': 20},
"           'lineText': 'export class SomeClass {'
"         }, {
"           'file': 'OtherClass.ts', 'isWriteAccess': 0, 
"           'start': {'line': 5', 'offset': 2}, 'end': {'line': 5, 'offset': 20},
"           'lineText': 'export class OtherClass extends SomeClass{'
"         }
"       ]
"     }
function! tsuquyomi#tsClient#tsReferences(file, line, offset)
  let l:arg = {'file': a:file, 'line': a:line, 'offset': a:offset}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('references', l:arg)
  return tsuquyomi#tsClient#getResponseBodyAsDict(l:result)
endfunction

" Reload an opend file.
" It can be used for telling change of buffer to TSServer.
" PARAM: {string} file File name 
" PARAM: {string} tmpfile
" RETURNS: {0|1} 
function! tsuquyomi#tsClient#tsReload(file, tmpfile)
  let l:arg = {'file': a:file, 'tmpfile': a:tmpfile}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('reload', l:arg)
  "echo l:result
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

" Fetch locatoins of symbols to be replaced from TSServer.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of the symbol's position.
" PARAM: {int} offset The col number of the symbol's position.
" PARAM: {0|1} findInComments Whether result contains word in comments.
" PARAM: {0|1} findInString Whether result contains word in String literals.
" RETURNS: {dict} Rename information dictionary.
"   e.g.:
"     {
"       'info': {
"         'canRename': 1,
"         'displayName': 'myApp',
"         'fullDisplayName': 'myApp',
"         'kind': 'class',
"         'kindModifiers': '',
"         'triggerSpan': {
"           'start': 44,
"           'length': 5
"         },
"       },
"       'locs': [{
"         'file': 'hoge.ts'', 
"         'locs': [
"           {'start':{'line': 3, 'offset': 4}, 'end':{'line': 3, 'offset': 12}},
"           ...
"         ]
"       },
"       ...,
"       ]
"     }
function! tsuquyomi#tsClient#tsRename(file, line, offset, findInComments, findInString)
  " TODO findInString parameter does not work... why?
  let l:arg = {'file': a:file, 'line': a:line, 'offset': a:offset,
        \ 'findInComments': a:findInComments ? s:JSON.true : s:JSON.false,
        \ 'findInString'  : a:findInString  ? s:JSON.true : s:JSON.false
        \ }
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('rename', l:arg)
  return tsuquyomi#tsClient#getResponseBodyAsDict(l:result)
endfunction

" Find brace matching pair.
" Vim has brace matching natively, so Tsuquyomi does not support this method.
function! tsuquyomi#tsClient#tsBrace(file, line, offset)
  call s:error('not implemented!')
endfunction

" ### TSServer command wrappers }}}

let &cpo = s:save_cpo
unlet s:save_cpo
