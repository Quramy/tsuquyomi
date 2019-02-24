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
let s:JSON = s:V.import('Web.JSON')
let s:Filepath = s:V.import('System.Filepath')

let s:is_vim8 = !has('nvim') && has('patch-8.0.1')

if !s:is_vim8 || g:tsuquyomi_use_vimproc
  let s:P = s:V.import('ProcessManager')
  let s:tsq = 'tsuquyomiTSServer'
else
  let s:tsq = {'job':0}
endif

let s:request_seq = 0

let s:ignore_response_conditions = []
" ignore events configFileDiag triggered by reload event. See also #99
call add(s:ignore_response_conditions, '"type":"event","event":"configFileDiag"')
call add(s:ignore_response_conditions, '"type":"event","event":"telemetry"')
call add(s:ignore_response_conditions, '"type":"event","event":"projectsUpdatedInBackground"')
call add(s:ignore_response_conditions, '"type":"event","event":"typingsInstallerPid"')
call add(s:ignore_response_conditions, 'npm notice created a lockfile')

" ### Async variables
let s:callbacks = {}
let s:notify_callback = {}
let s:quickfix_list = []
" ### }}}

" ### Utilites {{{
function! s:error(msg)
  echoerr (a:msg)
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
function! s:startTssVimproc()
  if s:P.state(s:tsq) == 'existing'
    return 'existing'
  endif
  let l:cmd = substitute(tsuquyomi#config#tsscmd(), '\\', '\\\\', 'g').' '.tsuquyomi#config#tssargs()
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

function! s:startTssVim8()
  if type(s:tsq['job']) == 8 && job_info(s:tsq['job']).status == 'run'
    return 'existing'
  endif
  let l:cmd = substitute(tsuquyomi#config#tsscmd(), '\\', '\\\\', 'g').' '.tsuquyomi#config#tssargs()
  try
    let s:tsq['job'] = job_start(l:cmd, {
      \ 'out_cb': {ch, msg -> tsuquyomi#tsClient#handleMessage(ch, msg)},
      \ })

    let s:tsq['channel'] = job_getchannel(s:tsq['job'])

    let out = ch_readraw(s:tsq['channel'])
    let st = tsuquyomi#tsClient#statusTss()
    if !g:tsuquyomi_tsserver_debug
      if err != ''
        call s:error('Fail to start TSServer... '.err)
        return 0
      endif
    endif
  catch
    return 0
  endtry
  return 1
endfunction

function! s:getEventType(item)
  if type(a:item) == v:t_dict
    \ && has_key(a:item, 'type')
    \ && a:item.type ==# 'event'
    \ && (a:item.event ==# 'syntaxDiag'
      \ || a:item.event ==# 'semanticDiag'
      \ || a:item.event ==# 'requestCompleted')
    return 'diagnostics'
  endif
  return 0
endfunction


function! tsuquyomi#tsClient#startTss()
  if !s:is_vim8 || g:tsuquyomi_use_vimproc
    return s:startTssVimproc()
  else
    return s:startTssVim8()
  endif
endfunction

"
"Terminate TSServer process if it exsits.
function! tsuquyomi#tsClient#stopTss()
  if tsuquyomi#tsClient#statusTss() != 'dead'
    if !s:is_vim8 || g:tsuquyomi_use_vimproc
      let l:res = s:P.term(s:tsq)
      return l:res
    else
      let l:res = job_stop(s:tsq['job'])
      return l:res
    endif
  endif
endfunction

function! tsuquyomi#tsClient#stopTssSync() abort
  let res = tsuquyomi#tsClient#stopTss()
  call s:ensureStatus('dead')
  return res
endfunction

" Wait for the status to become the argument.
" Note: It throws an error to avoid infinite loop after 1s.
function! s:ensureStatus(expected) abort
  let cnt = 0
  while v:true
    let got = tsuquyomi#tsClient#statusTss()
    if got ==# a:expected
      return
    endif
    if cnt > 100
      throw "TSServer status does not become " . a:expected . " in 1s. It is " . got . "."
    endif
    let cnt += 1
    sleep 10m
  endwhile
endfunction

" RETURNS: {string} 'run' or 'dead'
function! tsuquyomi#tsClient#statusTss()
  try
    if !s:is_vim8 || g:tsuquyomi_use_vimproc
      let stat = s:P.state(s:tsq)
      if stat == 'undefined'
        return 'dead'
      elseif stat == 'reading'
        return 'run'
      else
        return stat
      endif
    else
      return job_info(s:tsq['job']).status
    endif
  catch
    return 'dead'
  endtry
endfunction

"
"Read diagnostics and add to QuickList.
"
" PARAM: {dict} response
function! tsuquyomi#tsClient#readDiagnostics(item)
  if a:item.event == 'requestCompleted'
    if has_key(s:notify_callback, 'diagnostics')
      let Callback = function(s:notify_callback['diagnostics'], [s:quickfix_list])
      call Callback()
      let s:quickfix_list = []
      let s:request_seq = s:request_seq + 1
    endif
  else
    " Cache syntaxDiag and semanticDiag messages until request was completed.
    let l:qflist = tsuquyomi#parseDiagnosticEvent(a:item, [])
    let s:quickfix_list += l:qflist
  endif
endfunction

function! tsuquyomi#tsClient#registerNotify(callback, key)
  let s:notify_callback[a:key] = a:callback
endfunction

"
" Handle TSServer responses.
"
function! tsuquyomi#tsClient#handleMessage(ch, msg)
  if type(a:msg) != 1 || a:msg == ''
    " Not a string or blank message.
    return
  endif
  let l:res_item = substitute(a:msg, 'Content-Length: \d\+', '', 'g')
  if l:res_item == ''
    " Ignore content-length.
    return
  endif
  " Ignore messages.
  let l:to_be_ignored = 0
  for ignore_reg in s:ignore_response_conditions
    let l:to_be_ignored = l:to_be_ignored || (l:res_item =~ ignore_reg)
    if l:to_be_ignored
      return
    endif
  endfor
  let l:item = json_decode(l:res_item)
  let l:eventName = s:getEventType(l:item)

  if(has_key(s:callbacks, l:eventName))
    let Callback = function(s:callbacks[l:eventName], [l:item])
    call Callback()
  endif
endfunction

function! tsuquyomi#tsClient#clearCallbacks()
  let s:callbacks = {}
endfunction

function! tsuquyomi#tsClient#registerCallback(callback, eventName)
  let s:callbacks[a:eventName] = a:callback
endfunction

function! tsuquyomi#tsClient#sendAsyncRequest(line)
  if s:is_vim8 && g:tsuquyomi_use_vimproc == 0
    call tsuquyomi#tsClient#startTss()
    call ch_sendraw(s:tsq['channel'], a:line . "\n")
  endif
endfunction

"
"Write to stdin of tsserver proc, and return stdout.
"
" PARAM: {string} line Stdin input.
" PARAM: {float} delay Wait time(sec) after request, until response.
" PARAM: {int} retry_count Retry count.
" PARAM: {int} response_length The number of JSONs contained by this response.
" RETURNS: {list<dict>} A list of response.
function! tsuquyomi#tsClient#sendRequest(line, delay, retry_count, response_length)
  "call s:debugLog('called! '.a:line)
  call tsuquyomi#tsClient#startTss()
  if !s:is_vim8 || g:tsuquyomi_use_vimproc
    call s:P.writeln(s:tsq, a:line)
  else
    call ch_sendraw(s:tsq['channel'], a:line."\n")
  endif

  let l:retry = 0
  let response_list = []

  while len(response_list) < a:response_length
    if !s:is_vim8 || g:tsuquyomi_use_vimproc
      let [out, err, type] = s:P.read_wait(s:tsq, a:delay, ['Content-Length: \d\+'])
      call s:debugLog('out: '.out.', type:'.type)
      if type == 'timedout'
        let retry_delay = 0.05
        while l:retry < a:retry_count
          let [out, err, type] = s:P.read_wait(s:tsq, retry_delay, ['Content-Length: \d\+'])
          if type == 'matched'
            call tsuquyomi#perfLogger#record('tssMatched')
            "call s:debugLog('retry: '.l:retry.', length: '.len(response_list))
            break
          endif
          let l:retry = l:retry + 1
          call tsuquyomi#perfLogger#record('tssRetry:'.l:retry)
        endwhile
      endif
    else
      let out = ch_readraw(s:tsq['channel'])
      let type = 'matched'
    endif
    if type == 'matched'
      let l:tmp1 = substitute(out, 'Content-Length: \d\+', '', 'g')
      let l:tmp2 = substitute(l:tmp1, '\r', '', 'g')
      let l:res_list = split(l:tmp2, '\n\+')
      for res_item in l:res_list
        let l:to_be_ignored = 0
        for ignore_reg in s:ignore_response_conditions + ['"type":"event","event":"requestCompleted"']
          let l:to_be_ignored = l:to_be_ignored || (res_item =~ ignore_reg)
          if l:to_be_ignored
            break
          endif
        endfor
        let l:decoded_res_item = s:JSON.decode(res_item)
        let l:to_be_ignored = l:to_be_ignored || (has_key(l:decoded_res_item, 'request_seq') && l:decoded_res_item.request_seq != s:request_seq)
        if !l:to_be_ignored
          call add(response_list, decoded_res_item)
        endif
      endfor
    else
      echom '[Tsuquyomi] TSServer request was timeout:'.a:line
      return response_list
    endif

  endwhile
  "call s:debugLog(a:response_length.', '.len(response_list))
  let s:request_seq = s:request_seq + 1
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
  call tsuquyomi#perfLogger#record('beforeCmd:'.a:cmd)
  let l:stdout_list = tsuquyomi#tsClient#sendRequest(l:input, str2float("0.0001"), 1000, 1)
  call tsuquyomi#perfLogger#record('afterCmd:'.a:cmd)
  let l:length = len(l:stdout_list)
  if l:length == 1
    "if res.success == 0
    "  echom '[Tsuquyomi] TSServer command fail. command: '.res.command.', message: '.res.message
    "endif
    call tsuquyomi#perfLogger#record('afterDecode:'.a:cmd)
    return l:stdout_list
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
    for res in l:stdout_list
      if res.type != 'event'
        "echom '[Tsuquyomi] TSServer return invalid response: '.string(res)
      else
        call add(l:result_list, res)
      endif
    endfor
    return l:result_list
  else
    return []
  endif

endfunction

function! tsuquyomi#tsClient#sendCommandOneWay(cmd, args)
  let l:input = s:JSON.encode({'command': a:cmd, 'arguments': a:args, 'type': 'request', 'seq': s:request_seq})
  call tsuquyomi#tsClient#sendRequest(l:input, str2float("0.01"), 0, 0)
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
" Send a command to TSServer.
" This function is called asynchronously.
" PARAM: {string} cmd Command type. e.g. 'completion', etc...
" PARAM: {dictionary} args Arguments object. e.g. {'file': 'myApp.ts'}.
function! tsuquyomi#tsClient#sendCommandAsyncEvents(cmd, args)
  let s:quickfix_list = []
  let l:input = json_encode({'command': a:cmd, 'arguments': a:args, 'type': 'request', 'seq': s:request_seq})
  " call tsuquyomi#perfLogger#record('beforeCmd:'.a:cmd)
  call tsuquyomi#tsClient#sendAsyncRequest(l:input)
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

" Configure editor parameter
" PARAM: {string} file File name.
" PARAM: {string} hostInfo Information of Vim
" PARAM: {dict} formatOptions Options for editor. See the following FormatCodeSetting interface.
" PARAM: {list} extraFileExtensions List of extensions
"
"    interface FormatCodeSetting {
"        baseIndentSize?: number;
"        indentSize?: number;
"        tabSize?: number;
"        newLineCharacter?: string;
"        convertTabsToSpaces?: boolean;
"        indentStyle?: IndentStyle | ts.IndentStyle;
"        insertSpaceAfterCommaDelimiter?: boolean;
"        insertSpaceAfterSemicolonInForStatements?: boolean;
"        insertSpaceBeforeAndAfterBinaryOperators?: boolean;
"        insertSpaceAfterConstructor?: boolean;
"        insertSpaceAfterKeywordsInControlFlowStatements?: boolean;
"        insertSpaceAfterFunctionKeywordForAnonymousFunctions?: boolean;
"        insertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis?: boolean;
"        insertSpaceAfterOpeningAndBeforeClosingNonemptyBrackets?: boolean;
"        insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces?: boolean;
"        insertSpaceAfterOpeningAndBeforeClosingTemplateStringBraces?: boolean;
"        insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces?: boolean;
"        insertSpaceBeforeFunctionParenthesis?: boolean;
"        placeOpenBraceOnNewLineForFunctions?: boolean;
"        placeOpenBraceOnNewLineForControlBlocks?: boolean;
"    }
let s:NON_BOOLEAN_KEYS_IN_FOPT = [ 'baseIndentSize', 'indentSize', 'tabSize', 'newLineCharacter', 'convertTabsToSpaces', 'indentStyle' ]
function! tsuquyomi#tsClient#tsConfigure(file, hostInfo, formatOptions, extraFileExtensions)
  let fopt = { }
  for k in keys(a:formatOptions)
    if index(s:NON_BOOLEAN_KEYS_IN_FOPT, k) != -1
      let fopt[k] = a:formatOptions[k]
    else
      let fopt[k] = a:formatOptions[k] ? s:JSON.true : s.JSON.false
    endif
  endfor
  let l:args = {
        \ 'file': a:file,
        \ 'hostInfo': a:hostInfo,
        \ 'formatOptions': fopt,
        \ 'extraFileExtensions': a:extraFileExtensions
        \ }
  return tsuquyomi#tsClient#sendCommandOneWay('configure', l:args)
endfunction

" Fetch location where the symbol at cursor(line, offset) in file is defined.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of location to complete.
" PARAM: {int} offset The col number of location to complete.
" RETURNS: {list<dict>} A list of dictionaries of definition location.
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

" Get error for files.
" PARAM: {list<string>} files List of filename
" PARAM: {int} delay Delay time [msec].
" PARAM: {list<dict>} error event list
function! tsuquyomi#tsClient#tsGeterr(files, delay)
  let l:args = {'files': a:files, 'delay': a:delay}
  let l:delaySec = a:delay * 1.0 / 1000.0
  let l:typeCount =   tsuquyomi#config#isHigher(280) ? 3 : 2
  let l:result = tsuquyomi#tsClient#sendCommandSyncEvents('geterr', l:args, l:delaySec, len(a:files) * l:typeCount)
  return l:result
endfunction

" Get errors for project.
" This command is available only at tsserver ~v.1.6
" PARAM: {string} file File name in target project.
" PARAM: {int} delay Delay time [msec].
" PARAM: {count} count The number of files in the project(you can fetch this from tsProjectInfo).
" PARAM: {list<dict>} error event list
function! tsuquyomi#tsClient#tsGeterrForProject(file, delay, count)
  let l:args = {'file': a:file, 'delay': a:delay}
  let l:delaySec = a:delay * 1.0 / 1000.0
  let l:typeCount =   tsuquyomi#config#isHigher(280) ? 3 : 2
  let l:result = tsuquyomi#tsClient#sendCommandSyncEvents('geterrForProject', l:args, l:delaySec, a:count * l:typeCount)
  return l:result
endfunction

" Fetch a list of implementations of an interface.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of the symbol's position.
" PARAM: {int} offset The col number of the symbol's position.
" RETURNS: {list<dict>} Reference information.
"   e.g. :
"     [
"       {
"         'file': 'SomeClass.ts',
"         'start': {'offset': 11, 'line': 23}, 'end': {'offset': 5, 'line': 35}
"       }, {
"         'file': 'OtherClass.ts',
"         'start': {'offset': 31, 'line': 26}, 'end': {'offset': 68, 'line': 26}
"       }
"     ]
function! tsuquyomi#tsClient#tsImplementation(file, line, offset)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('implementation', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsList(l:result)
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
  let l:args = {'file': a:file, 'searchValue': a:searchValue, 'maxResultCount': a:maxResultCount}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('navto', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsList(l:result)
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
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('references', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsDict(l:result)
endfunction

" Reload an opend file.
" It can be used for telling change of buffer to TSServer.
" PARAM: {string} file File name
" PARAM: {string} tmpfile
" RETURNS: {0|1}
function! tsuquyomi#tsClient#tsReload(file, tmpfile)
  let l:arg = {'file': a:file, 'tmpfile': a:tmpfile}
  " With ts > 2.6 and ts <=1.9, tsserver emit 2 responses by reload request.
  " ignore 2nd response of reload command. See also #62
  if tsuquyomi#config#isHigher(260) || !tsuquyomi#config#isHigher(190)
    let l:res_count = 1
  else
    let l:res_count = 2
  endif
  let l:result = tsuquyomi#tsClient#sendCommandSyncEvents('reload', l:arg, 0.01, l:res_count)
  "echo l:result
  if(len(l:result) >= 1)
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

" This command is available only at tsserver ~v.1.6
function! tsuquyomi#tsClient#tsDocumentHighlights(file, line, offset, filesToSearch)
  call s:error('not implemented!')
endfunction

" Fetch project information.
" This command is available only at tsserver ~v.1.6
" PARAM: {string} file File name.
" PARAM: {0|1} needFileNameList Whether include list of files in response.
" RETURNS: dict Project information dictionary.
"   e.g.:
"     {
"       'configFileName': '/samplePrjs/prj001/tsconfig.json',
"       'fileNames': [
"         '/PATH_TO_TYPESCRIPT/node_modules/typescript/lib/lib.d.ts',
"         '/samplePrjs/prj001/main.ts'
"       ]
"     }
function! tsuquyomi#tsClient#tsProjectInfo(file, needFileNameList)
  let l:arg = {'file': a:file,
        \ 'needFileNameList': a:needFileNameList ? s:JSON.true : s:JSON.false
        \ }
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('projectInfo', l:arg)
  return tsuquyomi#tsClient#getResponseBodyAsDict(l:result)
endfunction

" Fetch method signature information from TSServer.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of the symbol's position.
" PARAM: {int} offset The col number of the symbol's position.
" RETURNS:  {dict}
"   e.g. :
"     {
"       'selectedItemIndex': 0,
"       'argumentCount': 1,
"       'argumentIndex': 0,
"       'applicableSpan': {
"         'start': { 'offset': 27, 'line': 25 }, 'end': { 'offset': 40, 'line': 25 }
"       },
"       'items': [{
"         'tags': [],
"         'separatorDisplayParts': [
"           { 'kind': 'punctuation', 'text': ',' },
"           { 'kind': 'space', 'text': ' ' }
"         ],
"         'prefixDisplayParts': [
"           { 'kind': 'methodName', 'text': 'deleteTerms' },
"           { 'kind': 'punctuation', 'text': '(' }
"         ],
"         'parameters': [
"           {
"             'isOptional': 0,
"             'name': 'id',
"             'documentation': [],
"             'displayParts': [
"               { 'kind': 'parameterName', 'text': 'id' },
"               { 'kind': 'punctuation', 'text': ':' },
"               { 'kind': 'space', 'text': ' ' },
"               { 'kind': 'keyword', 'text': 'number' }
"             ]
"           }
"         ],
"         'suffixDisplayParts': [
"           { 'kind': 'punctuation', 'text': ')' },
"           { 'kind': 'punctuation', 'text': ':' },
"           { 'kind': 'space', 'text': ' ' },
"           { 'kind': 'className', 'text': 'Observable' },
"           { 'kind': 'punctuation', 'text': '<' },
"           { 'kind': 'interfaceName', 'text': 'ApiResponseData' },
"           { 'kind': 'punctuation', 'text': '>' }
"         ],
"         'isVariadic': 0,
"         'documentation': []
"       }]
"     }
"
" This can be combined into a simple signature like this:
"     deleteTerms(id: number): Observable<ApiResponseData>
function! tsuquyomi#tsClient#tsSignatureHelp(file, line, offset)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('signatureHelp', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsDict(l:result)
endfunction

" Fetch location where the type of the symbol at cursor(line, offset) in file is defined.
" PARAM: {string} file File name.
" PARAM: {int} line The line number of location to complete.
" PARAM: {int} offset The col number of location to complete.
" RETURNS: {list<dict>} A list of dictionaries of type definition location.
"   e.g. :
"     [{'file': 'hogehoge.ts', 'start': {'line': 3, 'offset': 2}, 'end': {'line': 3, 'offset': 10}}]
function! tsuquyomi#tsClient#tsTypeDefinition(file, line, offset)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset}
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('typeDefinition', l:args)
  return tsuquyomi#tsClient#getResponseBodyAsList(l:result)
endfunction

" Reload prjects.
" This command is available only at tsserver ~v.1.6
" This command does not return any response.
function! tsuquyomi#tsClient#tsReloadProjects()
  return tsuquyomi#tsClient#sendCommandOneWay('reloadProjects', {})
endfunction

" This command is available only at tsserver ~v.2.1
" PARAM: {string} file File name.
" PARAM: {number} startLine The line number for the req
" PARAM: {number} startOffset The character offset for the req
" PARAM: {number} endLine The line number for the req
" PARAM: {number} endOffset The character offset for the req
" PARAM: {list<number>} errorCodes Error codes we want to get the fixes for
" RETURNS: {list<dict>}
"   e.g.:
"     [
"       {
"         'description': 'Add missing ''super()'' call.',
"         'changes': [
"           {
"             'fileName': '/SamplePrj/codeFixesTest.ts',
"             'textChanges': [
"               {
"                 'start': {'offset': 20, 'line': 6},
"                 'end': {'offset': 20, 'line': 6},
"                 'newText': 'super();'
"               }
"             ]
"           }
"         ]
"       }
"     ]
function! tsuquyomi#tsClient#tsGetCodeFixes(file, startLine, startOffset, endLine, endOffset, errorCodes)
  let l:arg = {
        \ 'file': a:file,
        \ 'startLine': a:startLine, 'startOffset': a:startOffset,
        \ 'endLine': a:endLine, 'endOffset': a:endOffset,
        \ 'errorCodes': a:errorCodes
        \ }
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('getCodeFixes', l:arg)
  return tsuquyomi#tsClient#getResponseBodyAsList(l:result)
endfunction

" Get available code fixes list
" This command is available only at tsserver ~v.2.1
function! tsuquyomi#tsClient#tsGetSupportedCodeFixes()
  let l:result = tsuquyomi#tsClient#sendCommandSyncResponse('getSupportedCodeFixes', {})
  let l:body = tsuquyomi#tsClient#getResponseBodyAsDict(l:result)
  if (type(l:body) != v:t_list)
    return []
  else
    return l:body
  endif
endfunction

"
" Emmit to change file to TSServer.
" Param: {string} file File name to change.
" Param: {int} line The line number of starting point of range to change.
" Param: {int} offset The col number of starting point of range to change.
" Param: {int} endLine The line number of end point of range to change.
" Param: {int} endOffset The col number of end point of range to change.
" Param: {string} insertString String after replacing
" This command does not return any response.
function! tsuquyomi#tsClient#tsAsyncChange(file, line, offset, endLine, endOffset, insertString)
  let l:args = {'file': a:file, 'line': a:line, 'offset': a:offset, 'endLine': a:endLine, 'endOffset': a:endOffset, 'insertString': a:insertString}
  call tsuquyomi#tsClient#sendCommandAsyncEvents('change', l:args)
endfunction

"
" Get error for files.
" PARAM: {list<string>} files List of filename
" PARAM: {int} delay Delay time [msec].
function! tsuquyomi#tsClient#tsAsyncGeterr(files, delay)
  let l:args = {'files': a:files, 'delay': a:delay}
  let l:delaySec = a:delay * 1.0 / 1000.0
  let l:typeCount = tsuquyomi#config#isHigher(280) ? 3 : 2
  call tsuquyomi#tsClient#sendCommandAsyncEvents('geterr', l:args)
endfunction

" ### TSServer command wrappers }}}

let &cpo = s:save_cpo
unlet s:save_cpo
