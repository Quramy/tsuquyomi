"============================================================================
" FILE: tsuquyomi.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = expand('<sfile>:p:h')
"let s:root_dir = s:Filepath.join(s:script_dir, '../')
let s:root_dir = s:Filepath.dirname(s:Filepath.dirname(s:Filepath.remove_last_separator(s:Filepath.join(s:script_dir, '../'))))
"
" ### Utilites {{{
function! s:error(msg)
  echom (a:msg)
  throw 'tsuquyomi: '.a:msg
endfunction

function! s:normalizePath(path)
  return substitute(a:path, '\\', '/', 'g')
endfunction

function! s:joinParts(displayParts)
  return join(map(a:displayParts, 'v:val.text'), '')
endfunction

function! s:joinPartsIgnoreBreak(displayParts, replaceString)
  let l:display = ''
  for part in a:displayParts
    if part.kind == 'lineBreak'
      let l:display = l:display.a:replaceString
      break
    endif
    let l:display = l:display.part.text
  endfor
  return l:display
endfunction

" Check whether files are opened.
" Found not opend file, show message.
function! s:checkOpenAndMessage(filelist)
  if tsuquyomi#tsClient#statusTss() == 'dead'
    return [[], a:filelist]
  endif
  let opened = []
  let not_opend = []
  for file in a:filelist
    if tsuquyomi#bufManager#isOpened(file)
      call add(opened, file)
    else
      call add(not_opend, file)
    endif
  endfor
  if len(not_opend)
    for file in not_opend
      if tsuquyomi#bufManager#isNotOpenable(file)
        echom '[Tsuquyomi] The buffer "'.file.'" is not valid filepath, so tusuqoymi cannot open this buffer.'
        return [opened, not_opend]
      endif
    endfor
    echom '[Tsuquyomi] Buffers ['.join(not_opend, ', ').'] are not opened by TSServer. Please exec command ":TsuquyomiOpen '.join(not_opend).'" and retry.'
  endif
  return [opened, not_opend]
endfunction

" Save current buffer to a temp file, and emit to reload TSServer.
" This function may be called for conversation with TSServer after user's change buffer.
function! s:flush()
  if tsuquyomi#bufManager#isDirty(expand('%:p'))
    let file_name = expand('%:p')
    call tsuquyomi#bufManager#saveTmp(file_name)
    call tsuquyomi#tsClient#tsReload(file_name, tsuquyomi#bufManager#tmpfile(file_name))
    call tsuquyomi#bufManager#setDirty(file_name, 0)
  endif
endfunction

function! s:is_valid_identifier(symbol_str)
  return a:symbol_str =~ '^[A-Za-z_\$][A-Za-z_\$0-9]*$'
endfunction

" Manually write content to the preview window.
" Opens a preview window to a scratch buffer named '__TsuquyomiScratch__'
function! s:writeToPreview(content)
  silent pedit __TsuquyomiScratch__
  silent wincmd P
  setlocal modifiable noreadonly
  setlocal nobuflisted buftype=nofile bufhidden=wipe ft=typescript
  put =a:content
  0d_
  setlocal nomodifiable readonly
  silent wincmd p
endfunction

function! s:setqflist(quickfix_list, ...)
  " 0: Do not close cwindow automatically
  " 1: Close cwindow automatically
  let auto_close = len(a:000) ? a:0 : 0
  call setqflist(a:quickfix_list, 'r')
  if len(a:quickfix_list) > 0
    cwindow
  else
    if auto_close != 0
      cclose
    endif
  endif
endfunction

let s:diagnostics_queue = []
let s:diagnostics_timer = -1
function! s:addDiagnosticsQueue(delay, bufnum)
  if index(s:diagnostics_queue, a:bufnum) != -1
    return
  endif

  if s:diagnostics_timer != -1
    call timer_stop(s:diagnostics_timer)
    let s:diagnostics_timer = -1
  endif

  call add(s:diagnostics_queue, a:bufnum)

  let s:diagnostics_timer = timer_start(
    \ a:delay,
    \ function('s:sendDiagnosticsQueue')
    \ )
endfunction

function! s:sendDiagnosticsQueue(timer) abort
  for l:bufnum in s:diagnostics_queue
    if !bufexists(l:bufnum)
      continue
    endif
    let l:file = tsuquyomi#emitChange(l:bufnum)
    let l:delayMsec = 50 "TODO export global option
    call tsuquyomi#tsClient#tsAsyncGeterr([l:file], l:delayMsec)
  endfor
  let s:diagnostics_queue = []
endfunction

" ### Utilites }}}

" ### Public functions {{{
"
function! tsuquyomi#rootDir()
  return s:root_dir
endfunction

" #### Server operations {{{
function! tsuquyomi#startServer()
  return tsuquyomi#tsClient#startTss()
endfunction

function! tsuquyomi#stopServer()
  call tsuquyomi#bufManager#clearMap()
  return tsuquyomi#tsClient#stopTss()
endfunction

function! tsuquyomi#statusServer()
  return tsuquyomi#tsClient#statusTss()
endfunction

" #### Server operations }}}

" #### Notify changed {{{
function! tsuquyomi#letDirty()
  return tsuquyomi#bufManager#setDirty(expand('%:p'), 1)
endfunction

function! tsuquyomi#flush()
  call s:flush()
endfunction
" #### Notify changed }}}

" #### File operations {{{
function! tsuquyomi#open(...)
  let filelist = a:0 ? map(range(1, a:{0}), 'expand(a:{v:val})') : [expand('%:p')]
  return s:openFromList(filelist)
endfunction

function! s:openFromList(filelist)
  for file in a:filelist
    if file == '' || tsuquyomi#bufManager#isNotOpenable(file) ||tsuquyomi#bufManager#isOpened(file)
      continue
    endif
    call tsuquyomi#tsClient#tsOpen(file)
    call tsuquyomi#bufManager#open(file)
  endfor
  return 1
endfunction

function! tsuquyomi#close(...)
  let filelist = a:0 ? map(range(1, a:{0}), 'expand(a:{v:val})') : [expand('%:p')]
  return s:closeFromList(filelist)
endfunction

function! s:closeFromList(filelist)
  let file_count = 0
  for file in a:filelist
    if tsuquyomi#bufManager#isOpened(file)
      call tsuquyomi#tsClient#tsClose(file)
      call tsuquyomi#bufManager#close(file)
      let file_count = file_count + 1
    endif
  endfor
  return file_count
endfunction

function! s:reloadFromList(filelist)
  let file_count = 0
  for file in a:filelist
    if tsuquyomi#bufManager#isOpened(file)
      call tsuquyomi#tsClient#tsReload(file, file)
    else
      call tsuquyomi#tsClient#tsOpen(file)
      call tsuquyomi#bufManager#open(file)
    endif
    call tsuquyomi#bufManager#setDirty(file, 0)
    let file_count = file_count + 1
  endfor
  return file_count
endfunction

function! tsuquyomi#reload(...)
  let filelist = a:0 ? map(range(1, a:{0}), 'expand(a:{v:val})') : [expand('%:p')]
  return s:reloadFromList(filelist)
endfunction

function! tsuquyomi#reloadProject()
  if tsuquyomi#config#isHigher(160)
    call tsuquyomi#tsClient#tsReloadProjects()
  else
    let filelist = values(map(tsuquyomi#bufManager#openedFiles(), 'v:val.bufname'))
    if len(filelist)
      call s:closeFromList(filelist)
      call s:openFromList(filelist)
    endif
  endif
endfunction

function! tsuquyomi#dump(...)
  let filelist = a:0 ? map(range(1, a:{0}), 'expand(a:{v:val})') : [expand('%:p')]
  let [opend, not_opend] = s:checkOpenAndMessage(filelist)

  for file in opend
    call tsuquyomi#tsClient#tsSaveto(file, file.'.dump')
  endfor
endfunction
" #### File operations }}}

" #### Project information {{{
function! tsuquyomi#projectInfo(file)
  if !tsuquyomi#config#isHigher(160)
    echom '[Tsuquyomi] This feature requires TypeScript@1.6.0 or higher'
    return {}
  endif
  if len(s:checkOpenAndMessage([a:file])[1])
    return {}
  endif
  let l:result = tsuquyomi#tsClient#tsProjectInfo(a:file, 1)
  let l:result.filteredFileNames = []
  if has_key(l:result, 'fileNames')
    for fileName in l:result.fileNames
      if fileName =~ 'typescript/lib/lib.d.ts$'
      else
        call add(l:result.filteredFileNames, fileName)
      endif
    endfor
  endif
  return l:result
endfunction
" }}}

" #### Complete {{{
"
function! tsuquyomi#setPreviewOption()
  " issue #41
  " I'll consider how to highlighting preview window without setting filetype.
  "
  " if &previewwindow
  "   setlocal ft=typescript
  " endif
endfunction

function! tsuquyomi#makeCompleteMenu(file, line, offset, entryNames)
  call tsuquyomi#perfLogger#record('tsCompletionEntryDetail')
  let res_list = tsuquyomi#tsClient#tsCompletionEntryDetails(a:file, a:line, a:offset, a:entryNames)
  call tsuquyomi#perfLogger#record('tsCompletionEntryDetail_done')
  let display_texts = []
  for result in res_list
    call add(display_texts, s:joinPartsIgnoreBreak(result.displayParts, '{...}'))
  endfor
  return display_texts
endfunction

" Get signature help information for preview window.
function! tsuquyomi#getSignatureHelp(file, line, offset)

  if stridx(&completeopt, 'preview') == -1
    return [0, '']
  endif

  let l:sig_dict = tsuquyomi#tsClient#tsSignatureHelp(a:file, a:line, a:offset)
  let has_info = 0
  if has_key(l:sig_dict, 'items') && len(l:sig_dict.items)
    let has_info = 1
    let info_lines = []

    for sigitem in l:sig_dict.items
      let siginfo_list = []
      let dispText = s:joinParts(sigitem.prefixDisplayParts)
      let params_list = []
      for paramInfo in sigitem.parameters
        let param_text =  s:joinParts(paramInfo.displayParts)
        if len(paramInfo.documentation)
          let param_text = param_text.'/* '.s:joinPartsIgnoreBreak(paramInfo.documentation, ' ...').' */'
        endif
        call add(params_list, param_text)
      endfor
      let dispText = dispText.join(params_list, ', ').s:joinParts(sigitem.suffixDisplayParts)
      if len(sigitem.documentation)
        let dispText = dispText.'/* '.s:joinPartsIgnoreBreak(sigitem.documentation, ' ...').' */'
      endif
      call add(info_lines, dispText)
    endfor

    let sigitem = l:sig_dict.items[0]
    return [has_info, join(info_lines, "\n\n")]
  endif

  return [has_info, '']
endfunction

" Comparator comparing on TypeScript CompletionEntry's 'sortText' property
" See https://github.com/Microsoft/TypeScript/blob/master/src/server/protocol.ts#L1483
function! s:sortTextComparator(entry1, entry2)
  if a:entry1.sortText < a:entry2.sortText
    return -1
  elseif a:entry1.sortText > a:entry2.sortText
    return 1
  else
    return 0
  endif
endfunction

function! tsuquyomi#signatureHelp()
  pclose

  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif

  call s:flush()

  let l:file = expand('%:p')
  let l:line = line('.')
  let l:offset = col('.')
  let [has_info, siginfo] = tsuquyomi#getSignatureHelp(l:file, l:line, l:offset)
  if has_info
    call s:writeToPreview(siginfo)
  endif
endfunction

function! tsuquyomi#complete(findstart, base)
  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif

  let l:line_str = getline('.')
  let l:line = line('.')
  let l:offset = col('.')

  " search backwards for start of identifier (iskeyword pattern)
  let l:start = l:offset
  while l:start > 0 && l:line_str[l:start-2] =~ "\\k"
    let l:start -= 1
  endwhile

  if(a:findstart)
    call tsuquyomi#perfLogger#record('before_flush')
    call s:flush()
    call tsuquyomi#perfLogger#record('after_flush')
    return l:start - 1
  else
    let l:file = expand('%:p')
    let l:res_dict = {'words': []}
    call tsuquyomi#perfLogger#record('before_tsCompletions')
    " By default the result list will be sorted by the 'name' properly alphabetically
    let l:alpha_sorted_res_list = tsuquyomi#tsClient#tsCompletions(l:file, l:line, l:start, a:base)
    call tsuquyomi#perfLogger#record('after_tsCompletions')

    let is_javascript = (&filetype == 'javascript') || (&filetype == 'jsx') || (&filetype == 'javascript.jsx')
    if is_javascript
      " Sort the result list according to how TypeScript suggests entries to be sorted
      let l:res_list = sort(copy(l:alpha_sorted_res_list), 's:sortTextComparator')
    else
      let l:res_list = l:alpha_sorted_res_list
    endif

    let enable_menu = stridx(&completeopt, 'menu') != -1
    let length = strlen(a:base)
    if enable_menu
      call tsuquyomi#perfLogger#record('start_menu')
      if g:tsuquyomi_completion_preview
        let [has_info, siginfo] = tsuquyomi#getSignatureHelp(l:file, l:line, l:start)
      else
        let [has_info, siginfo] = [0, '']
      endif

      let size = g:tsuquyomi_completion_chunk_size
      let j = 0
      while j * size < len(l:res_list)
        let entries = []
        let items = []
        let upper = min([(j + 1) * size, len(l:res_list)])
        for i in range(j * size, upper - 1)
          let info = l:res_list[i]
          if !length
                \ || !g:tsuquyomi_completion_case_sensitive && info.name[0:length - 1] == a:base
                \ || g:tsuquyomi_completion_case_sensitive && info.name[0:length - 1] ==# a:base
            let l:item = {'word': info.name, 'menu': info.kind }
            if has_info
              let l:item.info = siginfo
            endif
            if is_javascript && info.kind == 'warning'
              let l:item.menu = '' " Make display cleaner by not showing 'warning' as the type
            endif
            if !g:tsuquyomi_completion_detail
              call complete_add(l:item)
            else
              " if file is TypeScript, then always add to entries list to
              " fetch details. Or in the case of JavaScript, avoid adding to
              " entries list if ScriptElementKind is 'warning'. Because those
              " entries are just random identifiers that occur in the file.
              if !is_javascript || info.kind != 'warning'
                call add(entries, info.name)
              endif
              call add(items, l:item)
            endif
          endif
        endfor
        if g:tsuquyomi_completion_detail
          call tsuquyomi#perfLogger#record('before_completeMenu'.j)
          let menus = tsuquyomi#makeCompleteMenu(l:file, l:line, l:start, entries)
          call tsuquyomi#perfLogger#record('after_completeMenu'.j)
          let idx = 0
          for menu in menus
            let items[idx].menu = menu
            let items[idx].info = menu
            call complete_add(items[idx])
            let idx = idx + 1
          endfor
          " For JavaScript completion, there are entries whose
          " ScriptElementKind is 'warning'. tsserver won't have any details
          " returned for them, but they still need to be added at the end.
          for i in range(idx, len(items) - 1)
            call complete_add(items[i])
          endfor
        endif
        if complete_check()
          break
        endif
        let j = j + 1
      endwhile
      return []
    else
      return filter(map(l:res_list, 'v:val.name'), 'stridx(v:val, a:base) == 0')
    endif

  endif
endfunction
" ### Complete }}}

" #### Definition {{{
function! tsuquyomi#gotoDefinition(tsClientFunction, splitMode)
  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif

  call s:flush()

  let l:file = s:normalizePath(expand('%:p'))
  let l:line = line('.')
  let l:offset = col('.')
  let l:res_list = a:tsClientFunction(l:file, l:line, l:offset)
  let l:definition_split = a:splitMode > 0 ? a:splitMode : g:tsuquyomi_definition_split

  if(len(l:res_list) > 0)
    " If get result, go to last location.
    let l:info = l:res_list[len(l:res_list) - 1]
    if a:splitMode == 0 && l:file == l:info.file
      " Same file without split
      call tsuquyomi#bufManager#winPushNavDef(bufwinnr(bufnr('%')), l:file, {'line': l:line, 'col': l:offset})
      call cursor(l:info.start.line, l:info.start.offset)
    elseif l:definition_split == 0
      call tsuquyomi#bufManager#winPushNavDef(bufwinnr(bufnr('%')), l:file, {'line': l:line, 'col': l:offset})
      execute 'edit +call\ cursor('.l:info.start.line.','.l:info.start.offset.') '.l:info.file
    elseif l:definition_split == 1
      execute 'split +call\ cursor('.l:info.start.line.','.l:info.start.offset.') '.l:info.file
    elseif l:definition_split == 2
      execute 'vsplit +call\ cursor('.l:info.start.line.','.l:info.start.offset.') '.l:info.file
    elseif l:definition_split == 3
      execute 'tabedit +call\ cursor('.l:info.start.line.','.l:info.start.offset.') '.l:info.file
    endif
  else
    " If don't get result, do nothing.
  endif
endfunction

function! tsuquyomi#definition()
  call tsuquyomi#gotoDefinition(function('tsuquyomi#tsClient#tsDefinition'), 0)
endfunction

function! tsuquyomi#splitDefinition()
  call tsuquyomi#gotoDefinition(function('tsuquyomi#tsClient#tsDefinition'), 1)
endfunction

function! tsuquyomi#typeDefinition()
  call tsuquyomi#gotoDefinition(function('tsuquyomi#tsClient#tsTypeDefinition'), 0)
endfunction

function! tsuquyomi#goBack()
  let [type, result] = tsuquyomi#bufManager#winPopNavDef(bufwinnr(bufnr('%')))
  if !type
    echom '[Tsuquyomi] No items in navigation stack...'
    return
  endif
  let [file_name, loc] = [result.file_name, result.loc]
  if expand('%:p') == file_name
    call cursor(loc.line, loc.col)
  else
    execute 'edit +call\ cursor('.loc.line.','.loc.col.') '.file_name
  endif
endfunction

" #### Definition }}}

" #### References {{{
" Show reference on a location window.
function! tsuquyomi#getLocations(tsClientFunction, functionTitle)
  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif

  call s:flush()

  let l:file = expand('%:p')
  let l:line = line('.')
  let l:offset = col('.')

  " 1. Fetch reference information.
  let l:res = a:tsClientFunction(l:file, l:line, l:offset)

  let l:references = []
  if type(l:res) == v:t_dict && has_key(l:res, 'refs')
    let l:references = l:res.refs
  elseif type(l:res) == v:t_list
    let l:references = l:res
  endif

  if len(l:references) != 0
    let l:location_list = []
    " 2. Make a location list for `setloclist`
    for reference in l:references
      if has_key(reference, 'lineText')
        let l:location_info = {
              \'filename': fnamemodify(reference.file, ':~:.'),
              \'lnum': reference.start.line,
              \'col': reference.start.offset,
              \'text': reference.lineText
              \}
      else
        let l:location_info = {
              \'filename': fnamemodify(reference.file, ':~:.'),
              \'lnum': reference.start.line,
              \'col': reference.start.offset
              \}
      endif
      call add(l:location_list, l:location_info)
    endfor
    if len(l:location_list) > 0
      call setloclist(0, l:location_list, 'r')
      "3. Open location window.
      lwindow
    endif
  else
    echom '[Tsuquyomi] '.a:functionTitle.': Not found...'
  endif
endfunction

function! tsuquyomi#references()
  call tsuquyomi#getLocations(function('tsuquyomi#tsClient#tsReferences'), 'References')
endfunction

function! tsuquyomi#implementation()
  call tsuquyomi#getLocations(function('tsuquyomi#tsClient#tsImplementation'), 'Implementation')
endfunction

" #### References }}}

" #### Geterr {{{

function! tsuquyomi#asyncGeterr(...)
  if g:tsuquyomi_is_available == 1
    call tsuquyomi#registerNotify(function('s:setqflist'), 'diagnostics')

    let l:delay = len(a:000) ? a:1 : 0
    call tsuquyomi#asyncCreateFixlist(l:delay)
  endif
endfunction

function! tsuquyomi#parseDiagnosticEvent(event, supportedCodes)
  let quickfix_list = []
  let codes = len(a:supportedCodes) > 0 ? a:supportedCodes : s:supportedCodeFixes
  if has_key(a:event, 'type') && a:event.type ==# 'event' && (a:event.event ==# 'syntaxDiag' || a:event.event ==# 'semanticDiag')
    for diagnostic in a:event.body.diagnostics
      if diagnostic.text =~ "Cannot find module" && g:tsuquyomi_ignore_missing_modules == 1
        continue
      endif
      let item = {}
      let item.filename = a:event.body.file
      let item.lnum = diagnostic.start.line
      if(has_key(diagnostic.start, 'offset'))
        let item.col = diagnostic.start.offset
      endif
      let item.text = diagnostic.text
      if !has_key(diagnostic, 'code')
        continue
      endif
      let item.code = diagnostic.code
      let l:cfidx = index(codes, (diagnostic.code . ''))
      if l:cfidx >= 0
        let l:qfmark = '[QF available]'
        let item.text = diagnostic.code . l:qfmark . ': ' . item.text
      endif
      let item.availableCodeFix = l:cfidx >= 0
      let item.type = 'E'
      call add(quickfix_list, item)
    endfor
  endif
  return quickfix_list
endfunction

function! tsuquyomi#registerNotify(callback, eventName)
  call tsuquyomi#tsClient#registerNotify(a:callback, a:eventName)
endfunction

function! tsuquyomi#emitChange(bufnum)
  let l:input = join(getbufline(a:bufnum, 1, '$'), "\n") . "\n"
  let l:file = expand('%:p')

  " file, line, offset, endLine, endOffset, insertString
  call tsuquyomi#tsClient#tsAsyncChange(l:file, 1, 1, len(l:input), 1, l:input)

  return l:file
endfunction

function! tsuquyomi#asyncCreateFixlist(...)
  " Works only Vim8(+channel, +job)
  " We must register callbacks(handler and callback) before execute this.
  " See `tsuquyomi#config#initBuffer()`
  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return []
  endif

  let l:delay = len(a:000) ? a:1 : 0
  let l:bufnum = bufnr('%')

  " Tell TSServer to change for get syntaxDiag and semanticDiag errors.
  if delay > 0
    " Debunce request for Textchanged autocmd.
    call s:addDiagnosticsQueue(l:delay, l:bufnum)
  else
    " Cancel current timer
    if s:diagnostics_timer != -1
      call timer_stop(s:diagnostics_timer)
      let s:diagnostics_timer = -1
    endif

    let l:file = tsuquyomi#emitChange(l:bufnum)
    let l:delayMsec = 50 "TODO export global option
    call tsuquyomi#tsClient#tsAsyncGeterr([l:file], l:delayMsec)
  endif
endfunction

function! tsuquyomi#createQuickFixListFromEvents(event_list)
  if !len(a:event_list)
    return []
  endif
  let quickfix_list = []
  let supportedCodes = tsuquyomi#getSupportedCodeFixes()
  for event_item in a:event_list
    let items = tsuquyomi#parseDiagnosticEvent(event_item, supportedCodes)
    let quickfix_list = quickfix_list + items
  endfor
  return quickfix_list
endfunction

function! tsuquyomi#createFixlist()
  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return []
  endif
  call s:flush()

  let l:files = [expand('%:p')]
  let l:delayMsec = 50 "TODO export global option

  " 1. Fetch error information from TSServer.
  let result = tsuquyomi#tsClient#tsGeterr(l:files, l:delayMsec)

  " 2. Make a quick fix list for `setqflist`.
  return tsuquyomi#createQuickFixListFromEvents(result)
endfunction

function! tsuquyomi#geterr()
  let quickfix_list = tsuquyomi#createFixlist()

  call s:setqflist(quickfix_list, 1)
endfunction

function! tsuquyomi#geterrProject()

  if !tsuquyomi#config#isHigher(160)
    echom '[Tsuquyomi] This feature requires TypeScript@1.6.0 or higher'
    return
  endif

  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif

  call s:flush()
  let l:file = expand('%:p')

  " 1. Fetch Project info for event count.
  let l:pinfo = tsuquyomi#projectInfo(l:file)
  if !has_key(l:pinfo, 'filteredFileNames') || !len(l:pinfo.filteredFileNames)
    return
  endif

  " 2. Fetch error information from TSServer.
  let l:delayMsec = 50 "TODO export global option
  let l:result = tsuquyomi#tsClient#tsGeterrForProject(l:file, l:delayMsec, len(l:pinfo.filteredFileNames))

  " 3. Make a quick fix list for `setqflist`.
  let quickfix_list = tsuquyomi#createQuickFixListFromEvents(result)

  call s:setqflist(quickfix_list, 1)
endfunction

function! tsuquyomi#reloadAndGeterr()
  if tsuquyomi#tsClient#statusTss() != 'dead'
    return tsuquyomi#geterr()
  endif
endfunction

" #### Geterr }}}

" #### Balloon {{{
function! tsuquyomi#balloonexpr()
  call s:flush()
  let res = tsuquyomi#tsClient#tsQuickinfo(fnamemodify(buffer_name(v:beval_bufnr),":p"), v:beval_lnum, v:beval_col)
  if has_key(res, 'displayString')
    if (has_key(res, 'documentation') && res.documentation != '')
      return join([res.documentation, res.displayString], "\n\n")
    endif

    return res.displayString
  endif
endfunction

function! tsuquyomi#hint()
  call s:flush()
  let res = tsuquyomi#tsClient#tsQuickinfo(expand('%:p'), line('.'), col('.'))
  if has_key(res, 'displayString')
    if (has_key(res, 'documentation') && res.documentation != '')
      return join([res.documentation, res.displayString], "\n\n")
    endif

    return res.displayString
  else
    return '[Tsuquyomi] There is no hint at the cursor.'
  endif
endfunction

" #### Balloon }}}

" #### Rename {{{
function! tsuquyomi#renameSymbol()
  return s:renameSymbolWithOptions(0, 0)
endfunction

function! tsuquyomi#renameSymbolWithComments()
  return s:renameSymbolWithOptions(1, 0)
endfunction

function! tsuquyomi#renameSymbolWithStrings()
  return s:renameSymbolWithOptions(0, 1)
endfunction

function! tsuquyomi#renameSymbolWithCommentsStrings()
  return s:renameSymbolWithOptions(1, 1)
endfunction

function! s:renameSymbolWithOptions(findInComments, findInString)

  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif

  call s:flush()

  let l:filename = expand('%:p')
  let l:line = line('.')
  let l:offset = col('.')

  " * Make a list of locations of symbols to be replaced.
  let l:res_dict = tsuquyomi#tsClient#tsRename(l:filename, l:line, l:offset, a:findInComments, a:findInString)

  " * Check the symbol is renameable
  if !has_key(l:res_dict, 'info')
    echom '[Tsuquyomi] No symbol to be renamed'
    return
  elseif !l:res_dict.info.canRename
    echom '[Tsuquyomi] '.l:res_dict.info.localizedErrorMessage
    return
  endif

  " * Check affection only current buffer.
  if len(l:res_dict.locs) != 1 || s:normalizePath(expand('%:p')) != l:res_dict.locs[0].file
    let file_list = map(copy(l:res_dict.locs), 'v:val.file')
    let dirty_file_list = tsuquyomi#bufManager#whichDirty(file_list)
    call s:reloadFromList(dirty_file_list)
  endif

  " * Question user what new symbol name.
  echohl String
  let renameTo = input('[Tsuquyomi] New symbol name : ')
  echohl none
  if !s:is_valid_identifier(renameTo)
    echo ' '
    echom '[Tsuquyomi] It is a not valid identifer.'
    return
  endif

  let s:locs_dict = {}
  let s:rename_to = renameTo
  let s:other_buf_list = []

  " * Execute to replace symbols by location, by buffer
  for fileLoc in l:res_dict.locs
    let is_open = tsuquyomi#bufManager#isOpened(fileLoc.file)
    if !is_open
      let s:locs_dict[s:normalizePath(fileLoc.file)] = fileLoc.locs
      call add(s:other_buf_list, s:normalizePath(fileLoc.file))
      continue
    endif
    let buffer_name = tsuquyomi#bufManager#bufName(fileLoc.file)
    let s:locs_dict[buffer_name] = fileLoc.locs
    "echom 'fileLoc.file '.fileLoc.file.', '.buffer_name
    let changed_count = 0
    if buffer_name != expand('%:p')
      call add(s:other_buf_list, buffer_name)
      continue
    endif
  endfor

  if !g:tsuquyomi_save_onrename
    let changed_count = s:renameLocal(0)
    echohl String
    echo ' '
    echo 'Changed '.changed_count.' locations.'
    echohl none
    for otherbuf in s:other_buf_list
      execute('silent split +call\ s:renameLocal(0) '.otherbuf)
    endfor
  else
    echohl String
    let l:confirm = input('[Tsuquyomi] The symbol is located in '.(len(s:other_buf_list) + 1).' files. Really replace them? [Y/n]')
    echohl none
    if l:confirm != 'n' && l:confirm != 'no'
      call s:renameLocalSeq(-1)
    endif
  endif
endfunction

function! s:renameLocal(should_save)
  let changed_count = 0
  let filename = expand('%:p')
  let locations_in_buf = s:locs_dict[expand('%:p')]
  let renameTo = s:rename_to
  for span in locations_in_buf
    if span.start.line != span.end.line
      echom '[Tsuquyomi] this span is across multiple lines. '
      return
    endif

    let lineidx = span.start.line
    let linestr = getline(lineidx)
    if span.start.offset - 1
      let pre = linestr[:(span.start.offset - 2)]
      let post = linestr[(span.end.offset - 1):]
      let linestr = pre.renameTo.post
    else
      let post = linestr[(span.end.offset - 1):]
      let linestr = renameTo.post
    endif
    call setline(lineidx, linestr)
    let changed_count = changed_count + 1
  endfor
  call tsuquyomi#reload()
  if a:should_save
    write
  endif
  return changed_count
endfunction

function! s:renameLocalSeq(index)
  call s:renameLocal(1)
  if a:index + 1 < len(s:other_buf_list)
    let l:next = s:other_buf_list[a:index + 1]
    execute('silent edit +call\ s:renameLocalSeq('.(a:index + 1).') '.l:next)
  else
    echohl String
    echo ' '
    echo 'Changed '.(a:index + 2).' files successfuly.'
    echohl none
  endif
endfunction
" #### Rename }}}

" #### NavBar {{{
function! tsuquyomi#navBar()
  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return [[], 0]
  endif

  call s:flush()

  let l:filename = expand('%:p')

  let result_list = tsuquyomi#tsClient#tsNavBar(tsuquyomi#bufManager#normalizePath(l:filename))

  if len(result_list)
    return [result_list, 1]
  else
    return [[], 0]
  endif

endfunction
" #### NavBar }}}

" #### Navto {{{
function! tsuquyomi#navto(term, kindModifiers, matchKindType)

  if len(a:term) < g:tsuquyomi_search_term_min_length
    echom "[Tsuquyomi] search term's length should be greater than ".g:tsuquyomi_search_term_min_length."."
    return [[], 0]
  endif

  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return [[], 0]
  endif

  call s:flush()

  let l:filename = expand('%:p')

  let result_list = tsuquyomi#tsClient#tsNavto(tsuquyomi#bufManager#normalizePath(l:filename), a:term, 100)

  if len(result_list)
    let list = []
    for result in result_list
      let flg = 1
      if a:matchKindType == 1
        let flg = flg && (result.matchKind=='prefix' || result.matchKind=='exact')
      elseif a:matchKindType == 2
        let flg = flg && (result.matchKind=='exact')
      endif
      if a:kindModifiers != ''
        let flg = flg && has_key(result, 'kindModifiers') && result.kindModifiers=~a:kindModifiers
      endif
      if flg
        call add(list, result)
      endif
    endfor
    return [list, 1]
  else
    echohl Error
    echom "[Tsuquyomi] Nothing was hit."
    echohl none
    return [[], 0]
  endif

endfunction

function! tsuquyomi#navtoByLoclist(term, kindModifiers, matchKindType)
  let [result_list, res_code] = tsuquyomi#navto(a:term, a:kindModifiers, a:matchKindType)
  if res_code
    let l:location_list = []
    for navtoItem in result_list
      let text = navtoItem.kind.' '.navtoItem.name
      if has_key(navtoItem, 'kindModifiers')
        let text = navtoItem.kindModifiers.' '.text
      endif
      if has_key(navtoItem, 'containerName')
        if has_key(navtoItem, 'containerKind')
          let text = text.' in '.navtoItem.containerKind.' '.navtoItem.containerName
        else
          let text = text.' in '.navtoItem.containerName
        endif
      endif
      let l:location_info = {
            \'filename': navtoItem.file,
            \'lnum': navtoItem.start.line,
            \'col': navtoItem.start.offset,
            \'text': text
            \}
      call add(l:location_list, l:location_info)
    endfor
    if(len(l:location_list) > 0)
      call setloclist(0, l:location_list, 'r')
      lwindow
    endif
  endif
endfunction

function! tsuquyomi#navtoByLoclistContain(term)
  call tsuquyomi#navtoByLoclist(a:term, '', 0)
endfunction

function! tsuquyomi#navtoByLoclistPrefix(term)
  call tsuquyomi#navtoByLoclist(a:term, '', 1)
endfunction

function! tsuquyomi#navtoByLoclistExact(term)
  call tsuquyomi#navtoByLoclist(a:term, '', 2)
endfunction

" #### Navto }}}

" #### Configure {{{
function! tsuquyomi#sendConfigure()
  let l:file = expand('%:p')
  let l:hostInfo = &viminfo
  let l:formatOptions = { }
  let l:extraFileExtensions = []
  if exists('&shiftwidth')
    let l:formatOptions.baseIndentSize = &shiftwidth
    let l:formatOptions.indentSize = &shiftwidth
  endif
  if exists('&expandtab')
    let l:formatOptions.convertTabsToSpaces = &expandtab
  endif
  call tsuquyomi#tsClient#tsConfigure(l:file, l:hostInfo, l:formatOptions, l:extraFileExtensions)
endfunction
" #### }}}

" #### CodeFixes {{{

function! s:sortQfItemByColdiff(a, b)
  if a:a.coldiff < a:b.coldiff
    return -1
  endif
  if a:a.coldiff == a:b.coldiff
    return 0
  endif
  if a:a.coldiff > a:b.coldiff
    return 1
  endif
endfunction

let s:supportedCodeFixes = []
function! tsuquyomi#getSupportedCodeFixes()
  if !tsuquyomi#config#isHigher(210)
    return []
  endif
  if len(s:supportedCodeFixes)
    return s:supportedCodeFixes
  endif
  try
    let s:supportedCodeFixes = tsuquyomi#tsClient#tsGetSupportedCodeFixes()
    return s:supportedCodeFixes
  catch
    return []
  endtry
endfunction

function! tsuquyomi#quickFix()
  if !tsuquyomi#config#isHigher(210)
    echom '[Tsuquyomi] This feature requires TypeScript@2.1.0 or higher'
    return
  endif
  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif
  call s:flush()
  let l:file = expand('%:p')
  let l:line = line('.')
  let l:col = col('.')
  let l:qfList = tsuquyomi#createFixlist()
  call filter(l:qfList, 'v:val.lnum == l:line')
  if !len(l:qfList)
    echom '[Tsuquyomi] There is no error to fix'
    return
  endif
  if len(l:qfList) > 1
    let l:temp = []
    for qfItem in qfList
      let qfItem.coldiff = abs(qfItem.col - l:col)
      call add(l:temp, qfItem)
    endfor
    call sort(l:temp, function('s:sortQfItemByColdiff'))
    let l:target = l:temp[0]
  else
    let l:target = l:qfList[0]
  endif
  let l:supportedCodes = copy(tsuquyomi#getSupportedCodeFixes())
  call filter(l:supportedCodes, 'v:val == l:target.code')
  if !len(l:supportedCodes)
    echom '[Tsuquyomi] '.l:target.code.' has no quick fixes...'
    return
  endif
  let l:result_list = tsuquyomi#tsClient#tsGetCodeFixes(file, l:target.lnum, l:target.col, l:target.lnum, l:target.col, [l:target.code])
  if !len(l:result_list)
    echom '[Tsuquyomi] '.l:target.code.' has no quick fixes...'
    return
  endif
  let s:available_qf_descriptions = map(copy(l:result_list), 'v:val.description')
  let [description, isSelect] = tsuquyomi#selectQfDescription()
  if !isSelect
    return
  endif
  let l:changes = filter(l:result_list, 'v:val.description ==# description')[0].changes
  " TODO
  " allow other file
  for fileChange in l:changes
    if tsuquyomi#bufManager#normalizePath(l:file) !=# fileChange.fileName
      echom '[Tsuquyomi] Tsuquyomi does not support this code fix...'
      return
    endif
  endfor
  call tsuquyomi#applyQfChanges(l:changes)
endfunction

function! tsuquyomi#applyQfChanges(changes)
  for fileChange in a:changes
    " TODO
    " allow fileChange.fileName
    for textChange in fileChange.textChanges
      let linesCountForReplacement = textChange.end.line - textChange.start.line + 1
      let preSpan = strpart(getline(textChange.start.line), 0, textChange.start.offset - 1)
      let postSpan = strpart(getline(textChange.end.line), textChange.end.offset - 1)
      let repList = split(preSpan.textChange.newText.postSpan, '\n')
      let l:count = textChange.start.line
      for rLine in repList
        if l:count <= textChange.end.line
          call setline(l:count, rLine)
        else
          call append(l:count - 1, rLine)
        endif
        let l:count = l:count + 1
      endfor
    endfor
  endfor
endfunction

let s:available_qf_descriptions = []
function! tsuquyomi#selectQfComplete(arg_lead, cmd_line, cursor_pos)
  return join(s:available_qf_descriptions, "\n")
endfunction

function! tsuquyomi#selectQfDescription()
  echohl String
  if len(s:available_qf_descriptions) == 1
    let l:yn = input('[Tsuquyomi] Apply: "'.s:available_qf_descriptions[0].'" [y/N]')
    echohl none
    echo ' '
    if l:yn =~ 'N'
      return ['', 0]
    else
      return [s:available_qf_descriptions[0], 1]
    endif
  endif
  let l:selected_desc = input('[Tsuquyomi] You can apply 2 more than quick fixes. Select one (candidates are shown using TAB): ', '', 'custom,tsuquyomi#selectQfComplete')
  echohl none
  echo ' '
  if len(filter(copy(s:available_qf_descriptions), 'v:val==#l:selected_desc'))
    return [l:selected_desc, 1]
  else
    echohl Error
    echom '[Tsuquyomi] Invalid selection.'
    echohl none
    return ['', 0]
  endif
endfunction
"#### CodeFixes }}}

" ### Public functions }}}

let &cpo = s:save_cpo
unlet s:save_cpo
