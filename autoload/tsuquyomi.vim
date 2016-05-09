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
function! s:flash()
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

" Make complete information for preview window.
function! tsuquyomi#makeCompleteInfo(file, line, offset)

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
    return [has_info, join(info_lines, "\n")]
  endif

  return [has_info, '']
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
    call tsuquyomi#perfLogger#record('before_flash')
    call s:flash()
    call tsuquyomi#perfLogger#record('after_flash')
    return l:start - 1
  else
    let l:file = expand('%:p')
    let l:res_dict = {'words': []}
    call tsuquyomi#perfLogger#record('before_tsCompletions')
    let l:res_list = tsuquyomi#tsClient#tsCompletions(l:file, l:line, l:start, a:base)
    call tsuquyomi#perfLogger#record('after_tsCompletions')
    let enable_menu = stridx(&completeopt, 'menu') != -1
    let length = strlen(a:base)
    if enable_menu
      call tsuquyomi#perfLogger#record('start_menu')
      let [has_info, siginfo] = tsuquyomi#makeCompleteInfo(l:file, l:line, l:start)
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
            let l:item = {'word': info.name}
            call add(entries, info.name)
            call add(items, l:item)
          endif
        endfor
        call tsuquyomi#perfLogger#record('before_completeMenu'.j)
        let menus = tsuquyomi#makeCompleteMenu(l:file, l:line, l:start, entries)
        call tsuquyomi#perfLogger#record('after_completeMenu'.j)
        let idx = 0
        for menu in menus
          let items[idx].menu = menu
          if has_info
            let items[idx].info = siginfo
          endif
          call complete_add(items[idx])
          let idx = idx + 1
        endfor
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
function! tsuquyomi#definition()

  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif

  call s:flash()

  let l:file = s:normalizePath(expand('%:p'))
  let l:line = line('.')
  let l:offset = col('.')
  let l:res_list = tsuquyomi#tsClient#tsDefinition(l:file, l:line, l:offset)

  if(len(l:res_list) == 1)
    " If get result, go to the location.
    let l:info = l:res_list[0]
    if l:file == l:info.file
      " Same file
      call tsuquyomi#bufManager#winPushNavDef(bufwinnr(bufnr('%')), l:file, {'line': l:line, 'col': l:offset})
      call cursor(l:info.start.line, l:info.start.offset)
    elseif g:tsuquyomi_definition_split == 0
      call tsuquyomi#bufManager#winPushNavDef(bufwinnr(bufnr('%')), l:file, {'line': l:line, 'col': l:offset})
      execute 'edit +call\ cursor('.l:info.start.line.','.l:info.start.offset.') '.l:info.file
    elseif g:tsuquyomi_definition_split == 1
      " If other file, split window
      execute 'split +call\ cursor('.l:info.start.line.','.l:info.start.offset.') '.l:info.file
    elseif g:tsuquyomi_definition_split == 2
      execute 'vsplit +call\ cursor('.l:info.start.line.','.l:info.start.offset.') '.l:info.file
    elseif g:tsuquyomi_definition_split == 3
      execute 'tabedit +call\ cursor('.l:info.start.line.','.l:info.start.offset.') '.l:info.file
    endif
  else
    " If don't get result, do nothing.
  endif
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
function! tsuquyomi#references()

  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif

  call s:flash()

  let l:file = expand('%:p')
  let l:line = line('.')
  let l:offset = col('.')

  " 1. Fetch reference information.
  let l:res = tsuquyomi#tsClient#tsReferences(l:file, l:line, l:offset)

  if(has_key(l:res, 'refs') && len(l:res.refs) != 0)
    let l:location_list = []
    " 2. Make a location list for `setloclist`
    for reference in res.refs
      let l:location_info = {
            \'filename': reference.file,
            \'lnum': reference.start.line,
            \'col': reference.start.offset,
            \'text': reference.lineText
            \}
      call add(l:location_list, l:location_info)
    endfor
    if(len(l:location_list) > 0)
      call setloclist(0, l:location_list, 'r')
      "3. Open location window.
      lwindow
    endif
  else
    echom '[Tsuquyomi] References: Not found...'
  endif
endfunction
" #### References }}}

" #### Geterr {{{

function! tsuquyomi#createQuickFixListFromEvents(event_list)
  if !len(a:event_list)
    return []
  endif
  let quickfix_list = []
  for event_item in a:event_list
    if has_key(event_item, 'type') && event_item.type ==# 'event' && (event_item.event ==# 'syntaxDiag' || event_item.event ==# 'semanticDiag')
      for diagnostic in event_item.body.diagnostics
        let item = {}
        let item.filename = event_item.body.file
        let item.lnum = diagnostic.start.line
        if(has_key(diagnostic.start, 'offset'))
          let item.col = diagnostic.start.offset
        endif
        let item.text = diagnostic.text
        let item.type = 'E'
        call add(quickfix_list, item)
      endfor
    endif
  endfor
  return quickfix_list
endfunction

function! tsuquyomi#createFixlist()
  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return []
  endif
  call s:flash()

  let l:files = [expand('%:p')]
  let l:delayMsec = 50 "TODO export global option

  " 1. Fetch error information from TSServer.
  let result = tsuquyomi#tsClient#tsGeterr(l:files, l:delayMsec)

  " 2. Make a quick fix list for `setqflist`.
  return tsuquyomi#createQuickFixListFromEvents(result)
endfunction

function! tsuquyomi#geterr()
  let quickfix_list = tsuquyomi#createFixlist()

  call setqflist(quickfix_list, 'r')
  if len(quickfix_list) > 0
    cwindow
  else
    cclose
  endif
endfunction

function! tsuquyomi#geterrProject()

  if !tsuquyomi#config#isHigher(160)
    echom '[Tsuquyomi] This feature requires TypeScript@1.6.0 or higher'
    return
  endif

  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif

  call s:flash()
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

  call setqflist(quickfix_list, 'r')
  if len(quickfix_list) > 0
    cwindow
  else
    cclose
  endif
endfunction

function! tsuquyomi#reloadAndGeterr()
  if tsuquyomi#tsClient#statusTss() != 'undefined'
    return tsuquyomi#geterr()
  endif
endfunction

" #### Geterr }}}

" #### Balloon {{{
function! tsuquyomi#balloonexpr()

  "if tsuquyomi#tsClient#tsReload() != 'undefined'
  call s:flash()
  let l:filename = buffer_name(v:beval_bufnr)
  let res = tsuquyomi#tsClient#tsQuickinfo(l:filename, v:beval_lnum, v:beval_col)
  if has_key(res, 'displayString')
    return res.displayString
  endif
  "endif
endfunction

function! tsuquyomi#hint()
  call s:flash()
  let res = tsuquyomi#tsClient#tsQuickinfo(expand('%:p'), line('.'), col('.'))
  if has_key(res, 'displayString')
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

  call s:flash()

  let l:filename = expand('%:p')
  let l:line = line('.')
  let l:offset = col('.')

  " * Make a list of locations of symbols to be replaced.
  let l:res_dict = tsuquyomi#tsClient#tsRename(l:filename, l:line, l:offset, a:findInComments, a:findInString)

  " * Check the symbol is renameable
  if !has_key(l:res_dict, 'info') 
    echom '[Tsuquyomi] No symbol to be rename'
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

  call s:flash()

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

  if len(a:term) < 3
    echom "[Tsuquyomi] search term's length should be greater than 3."
    return [[], 0]
  endif

  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return [[], 0]
  endif

  call s:flash()

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

" #### Import {{{
function! s:get_keyword_under_cursor()
  let l:line_str = getline('.')
  let l:line = line('.')
  let l:offset = col('.')
  " search backwards for start of identifier (iskeyword pattern)
  let l:start = l:offset 
  let l:end = l:offset
  while l:start > 0 && l:line_str[l:start-2] =~ "\\k"
    let l:start -= 1
  endwhile
  while l:end <= strlen(l:line_str) && l:line_str[l:end] =~ "\\k"
    let l:end += 1
  endwhile
  return l:line_str[l:start-1:l:end-1]
endfunction

function! s:relativePath(from, to)
  let l:from_parts = s:Filepath.split(s:Filepath.dirname(a:from))
  let l:to_parts = s:Filepath.split(a:to)
  let l:count_node_modules = len(filter(copy(l:to_parts), 'v:val==#"node_modules"'))
  if l:count_node_modules > 1
    return ['', 0]
  elseif l:count_node_modules == 1
    return [substitute(a:to, '^.*\/node_modules\/', '', ''), 1]
  endif
  let l:idx = 0
  while idx < min([len(l:from_parts), len(l:to_parts)]) && l:from_parts[l:idx] ==# l:to_parts[l:idx]
    let l:idx += 1
  endwhile
  call remove(l:from_parts, 0, l:idx - 1)
  call remove(l:to_parts, 0, l:idx - 1)
  if len(l:from_parts)
    return [join(map(l:from_parts, '"../"'), '').join(l:to_parts, '/'), 1]
  else
    return ['./'.join(l:to_parts, '/'), 1]
  endif
endfunction

function! tsuquyomi#createImportBlock()
  let l:identifier = s:get_keyword_under_cursor()
  if !s:is_valid_identifier(l:identifier)
    return []
  endif
  let [l:nav_list, l:hit] = tsuquyomi#navto(l:identifier, 'export', 2)
  if !l:hit || !len(l:nav_list)
    return []
  endif
  let l:from = s:normalizePath(expand('%:p'))
  let l:result_list = []
  for nav in l:nav_list
    if has_key(nav, 'containerKind') && nav.containerKind ==# 'module'
      let l:importDict = {
            \ 'identifier': l:identifier,
            \ 'path': nav.containerName,
            \ 'nav': nav
            \ }
    else
      let l:to = s:normalizePath(nav.file)
      let [l:relative_path, l:result] = s:relativePath(l:from, l:to)
      if !l:result
        return []
      endif
      let l:relative_path= substitute(l:relative_path, '\.d\.ts$', '', '')
      let l:relative_path= substitute(l:relative_path, '\.ts$', '', '')
      let l:importDict = {
            \ 'identifier': l:identifier,
            \ 'path': l:relative_path,
            \ 'nav': nav
            \ }
    endif
    call add(l:result_list, l:importDict)
  endfor
  return l:result_list
endfunction

function!tsuquyomi#getImportList()
  let [l:nav_bar_list, l:result] = tsuquyomi#navBar()
  if !l:result
    return [[], 0, 'no_nav_bar']
  endif
  let l:module_infos = filter(l:nav_bar_list, 'v:val.kind ==# "module"')
  if !len(l:module_infos)
    return [[], 0, 'no_module_info']
  endif
  let l:result_list = []
  let l:module_end_line = l:module_infos[0].spans[0].end.line
  let l:alias_list = filter(l:module_infos[0].childItems, 'v:val.kind ==# "alias"')
  let l:end_line = l:module_end_line
  for alias in l:alias_list
    let l:hit = 0
    let [l:has_brace, l:brace] = [0, {}]
    let [l:has_from, l:from] = [0, { 'start': {}, 'end': {} }]
    let [l:has_module, l:module] = [0, { 'name': '', 'start': {}, 'end': {} }]
    let l:line = alias.spans[0].start.line
    while !l:hit && l:line <= l:end_line
      let l:line_str = getline(l:line)
      let l:brace_offset = match(l:line_str, '\}')
      let l:from_offset = match(l:line_str, 'from')
      if l:brace_offset + 1 && !l:has_from
        let l:has_brace = 1
        let l:brace = { 'offset': l:brace_offset + 1, 'line': l:line }
      endif
      if l:from_offset + 1
        let l:has_from = 1
        let l:from = {
              \ 'start': { 'offset': l:from_offset + 1, 'line': l:line },
              \ 'end': { 'offset': l:from_offset + 4, 'line': l:line }
              \ }
      endif
      if l:has_from
        let l:module_name_sq = matchstr(l:line_str, "\\m'\\zs.*\\ze'")
        if l:module_name_sq !=# ''
          let l:has_module = 1
          let l:module_name = l:module_name_sq
        else
          let l:module_name_dq = matchstr(l:line_str, '\m"\zs.*\ze"')
          if l:module_name_dq !=# ''
            let l:has_module = 1
            let l:module_name = l:module_name_dq
          endif
        endif
      endif
      if l:has_module
        let [l:hit, l:end_line] = [1, l:line]
        let l:module = {
              \ 'name': l:module_name,
              \ 'start': { 'line': l:line },
              \ 'end': { 'line': l:line },
              \ }
      else
        let l:line += 1
      endif
    endwhile
    if l:hit
      let l:info = {
            \ 'module': l:module,
            \ 'from_span': l:from,
            \ 'has_brace': l:has_brace,
            \ 'brace': l:brace,
            \ 'alias_info': alias,
            \ 'is_oneliner': alias.spans[0].start.line == l:module.end.line
            \ }
      call add(l:result_list, l:info)
    endif
  endfor
  return [l:result_list, l:result_list[-1].module.end.line, '']
endfunction

let s:impotable_module_list = []
function! tsuquyomi#moduleComplete(arg_lead, cmd_line, cursor_pos)
  return join(s:impotable_module_list, "\n")
endfunction

function! tsuquyomi#selectModule()
  echohl String
  let l:selected_module = input('[Tsuquyomi] You can import from 2 more than modules. Select one : ', '', 'custom,tsuquyomi#moduleComplete')
  echohl none 
  echo ' '
  if len(filter(copy(s:impotable_module_list), 'v:val==#l:selected_module'))
    return [l:selected_module, 1]
  else
    echohl Error
    echom '[Tsuquyomi] invalid module path.'
    echohl none
    return ['', 0]
  endif
endfunction

function! tsuquyomi#import()
  let l:list = tsuquyomi#createImportBlock()
  if len(l:list) > 1
    let s:impotable_module_list = map(copy(l:list), 'v:val.path')
    let [l:selected_module, l:code] = tsuquyomi#selectModule()
    if !l:code
      echohl Error
      echom '[Tsuquyomi] No search result.'
      echohl none
      return
    endif
    let l:block = filter(l:list, 'v:val.path==#l:selected_module')[0]
  elseif len(l:list) == 1
    let l:block = l:list[0]
  else
    return
  endif
  let [l:import_list, l:module_end_line, l:reason] = tsuquyomi#getImportList()
  let l:same_path_import_list = filter(l:import_list, 'v:val.has_brace && v:val.module.name ==# l:block.path')
  if !len(l:same_path_import_list)
    let l:expression = 'import { '.l:block.identifier.' } from "'.l:block.path.'";'
    call append(l:module_end_line, l:expression)
  else
    if len(filter(copy(l:same_path_import_list), 'v:val.alias_info.text ==# l:block.identifier'))
      echohl Error
      echom '[Tsuquyomi] '.l:block.identifier.' is already imported.'
      echohl none
      return
    endif
    let l:target_import = l:same_path_import_list[0]
    if l:target_import.is_oneliner
      let l:line = getline(l:target_import.brace.line)
      let l:expression = l:line[0:l:target_import.brace.offset - 2].', '.l:block.identifier.' '.l:line[l:target_import.brace.offset - 1: -1]
      call setline(l:target_import.brace.line, l:expression)
    else
      let l:before_line = getline(l:target_import.brace.line - 1)
      let l:indent = matchstr(l:before_line, '\m^\s*')
      call setline(l:target_import.brace.line - 1, l:before_line.',')
      call append(l:target_import.brace.line - 1, l:indent.l:block.identifier)
    endif
  endif
endfunction
" #### Import }}}

" ### Public functions }}}

let &cpo = s:save_cpo
unlet s:save_cpo
