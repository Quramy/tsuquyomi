"============================================================================
" FILE: autoload/tsuquyomi/es6import.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')

function! s:normalizePath(path)
  return substitute(a:path, '\\', '/', 'g')
endfunction

function! s:is_valid_identifier(symbol_str)
  return a:symbol_str =~ '^[A-Za-z_\$][A-Za-z_\$0-9]*$'
endfunction

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
  return {
        \ 'text': l:line_str[l:start-1:l:end-1],
        \ 'start': { 'offset': l:start, 'line': l:line },
        \ 'end': { 'offset': l:end, 'line': l:line }
        \ }
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

let s:external_module_cache_dict = {}
function! tsuquyomi#es6import#checkExternalModule(name, file, no_use_cache)
  let l:cache = s:external_module_cache_dict
  if a:no_use_cache || !has_key(l:cache, a:file) || !has_key(l:cache[a:file], a:name)
    if !has_key(l:cache, a:file)
      let l:cache[a:file] = {}
    endif
    let l:result = tsuquyomi#tsClient#tsNavBar(a:file)
    let l:modules = map(filter(l:result, 'v:val.kind==#"module"'), 'v:val.text')
    let l:cache[a:file][a:name] = 0
    for module_name in l:modules
      if module_name[0] ==# '"' || module_name[0] ==# "'"
        if module_name[1:-2] ==# a:name
          let l:cache[a:file][a:name] = 1
          break
        endif
      endif
    endfor
  endif
  return l:cache[a:file][a:name]
endfunction

function! tsuquyomi#es6import#createImportBlock(text)
  let l:identifier = a:text
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
      if tsuquyomi#es6import#checkExternalModule(nav.containerName, nav.file, 0)
        let l:importDict = {
              \ 'identifier': nav.name,
              \ 'path': nav.containerName,
              \ 'nav': nav
              \ }
        call add(l:result_list, l:importDict)
      endif
    else
      let l:to = s:normalizePath(nav.file)
      let [l:relative_path, l:result] = s:relativePath(l:from, l:to)
      if !l:result
        return []
      endif
      let l:relative_path = substitute(l:relative_path, '\.d\.ts$', '', '')
      let l:relative_path = substitute(l:relative_path, '\.ts$', '', '')
      let l:importDict = {
            \ 'identifier': nav.name,
            \ 'path': l:relative_path,
            \ 'nav': nav
            \ }
      call add(l:result_list, l:importDict)
    endif
  endfor
  return l:result_list
endfunction

function! s:comp_alias(alias1, alias2)
  return a:alias2.spans[0].end.line - a:alias1.spans[0].end.line
endfunction

function! tsuquyomi#es6import#createImportPosition(nav_bar_list)
  if !len(a:nav_bar_list)
    return {}
  endif
  if len(a:nav_bar_list) == 1
    if a:nav_bar_list[0].kind ==# 'module'
      if !len(filter(copy(a:nav_bar_list[0].childItems), 'v:val.kind ==#"alias"'))
        let l:start_line = a:nav_bar_list[0].spans[0].start.line - 1
        let l:end_line = l:start_line
      else
        let l:start_line = a:nav_bar_list[0].spans[0].start.line
        let l:end_line = a:nav_bar_list[0].spans[0].end.line
      endif
    else
      let l:start_line = a:nav_bar_list[0].spans[0].start.line - 1
      let l:end_line = l:start_line
    endif
  elseif len(a:nav_bar_list) > 1
      let l:start_line = a:nav_bar_list[0].spans[0].start.line
      let l:end_line = a:nav_bar_list[1].spans[0].start.line - 1
  endif
  return { 'start': { 'line': l:start_line }, 'end': { 'line': l:end_line } }
endfunction

function! tsuquyomi#es6import#getImportDeclarations(fileName, content_list)
  let l:nav_bar_list = tsuquyomi#tsClient#tsNavBar(a:fileName)
  if !len(l:nav_bar_list)
    return [[], {}, 'no_nav_bar']
  endif
  let l:position = tsuquyomi#es6import#createImportPosition(l:nav_bar_list)
  let l:module_infos = filter(copy(l:nav_bar_list), 'v:val.kind ==# "module"')
  if !len(l:module_infos)
    return [[], l:position, 'no_module_info']
  endif
  let l:result_list = []
  let l:alias_list = filter(l:module_infos[0].childItems, 'v:val.kind ==# "alias"')
  let l:end_line = position.end.line
  let l:last_module_end_line = 0
  for alias in sort(l:alias_list, "s:comp_alias")
    let l:hit = 0
    let [l:has_brace, l:brace] = [0, {}]
    let [l:has_from, l:from] = [0, { 'start': {}, 'end': {} }]
    let [l:has_module, l:module] = [0, { 'name': '', 'start': {}, 'end': {} }]
    let l:line = alias.spans[0].start.line
    while !l:hit && l:line <= l:end_line
      if !len(a:content_list)
        let l:line_str = getline(l:line)
      else
        let l:line_str = a:content_list[l:line - 1]
      endif
      let l:brace_end_offset = match(l:line_str, "}")
      let l:from_offset = match(l:line_str, 'from')
      if l:brace_end_offset + 1 && !l:has_brace && !l:has_from
        let l:has_brace = 1
        let l:brace = { 
              \ 'end': { 'offset': l:brace_end_offset + 1, 'line': l:line }
              \ }
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
        if !l:last_module_end_line
          let l:last_module_end_line = l:line
        endif
      else
        let l:line += 1
      endif
    endwhile
    if l:hit
      let l:info = {
            \ 'module': l:module,
            \ 'has_from': l:has_from,
            \ 'from_span': l:from,
            \ 'has_brace': l:has_brace,
            \ 'brace': l:brace,
            \ 'alias_info': alias,
            \ 'is_oneliner': alias.spans[0].start.line == l:module.end.line
            \ }
      call add(l:result_list, l:info)
    endif
  endfor
  if l:last_module_end_line
    let l:position.end.line = l:last_module_end_line
  endif
  return [l:result_list, l:position, '']
endfunction

let s:impotable_module_list = []
function! tsuquyomi#es6import#moduleComplete(arg_lead, cmd_line, cursor_pos)
  return join(s:impotable_module_list, "\n")
endfunction

function! tsuquyomi#es6import#selectModule()
  echohl String
  let l:selected_module = input('[Tsuquyomi] You can import from 2 more than modules. Select one : ', '', 'custom,tsuquyomi#es6import#moduleComplete')
  echohl none 
  echo ' '
  if len(filter(copy(s:impotable_module_list), 'v:val==#l:selected_module'))
    return [l:selected_module, 1]
  else
    echohl Error
    echom '[Tsuquyomi] Invalid module path.'
    echohl none
    return ['', 0]
  endif
endfunction

function! tsuquyomi#es6import#complete()
  if !tsuquyomi#bufManager#isOpened(expand('%:p'))
    return
  end
  call tsuquyomi#flush()
  let l:identifier_info = s:get_keyword_under_cursor()
  let l:list = tsuquyomi#es6import#createImportBlock(l:identifier_info.text)
  if len(l:list) > 1
    let s:impotable_module_list = map(copy(l:list), 'v:val.path')
    let [l:selected_module, l:code] = tsuquyomi#es6import#selectModule()
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
  let [l:import_list, l:dec_position, l:reason] = tsuquyomi#es6import#getImportDeclarations(expand('%:p'), [])
  let l:module_end_line = has_key(l:dec_position, 'end') ? l:dec_position.end.line : 0
  let l:same_path_import_list = filter(l:import_list, 'v:val.has_brace && v:val.module.name ==# l:block.path')
  if len(l:same_path_import_list) && len(filter(copy(l:same_path_import_list), 'v:val.alias_info.text ==# l:block.identifier'))
    echohl Error
    echom '[Tsuquyomi] '.l:block.identifier.' is already imported.'
    echohl none
    return
  endif

  "Replace search keyword to hit result identifer
  let l:line = getline(l:identifier_info.start.line)
  let l:new_line = l:block.identifier
  if l:identifier_info.start.offset > 1
    let l:new_line = l:line[0:l:identifier_info.start.offset - 2].l:new_line
  endif
  let l:new_line = l:new_line.l:line[l:identifier_info.end.offset: -1]
  call setline(l:identifier_info.start.line, l:new_line)

  "Add import declaration
  if !len(l:same_path_import_list)
    if g:tsuquyomi_single_quote_import
      let l:expression = "import { ".l:block.identifier." } from '".l:block.path."';"
    else
      let l:expression = 'import { '.l:block.identifier.' } from "'.l:block.path.'";'
    endif
    call append(l:module_end_line, l:expression)
  else
    let l:target_import = l:same_path_import_list[0]
    if l:target_import.is_oneliner
      let l:line = getline(l:target_import.brace.end.line)
      let l:expression = l:line[0:l:target_import.brace.end.offset - 2].', '.l:block.identifier.' '.l:line[l:target_import.brace.end.offset - 1: -1]
      call setline(l:target_import.brace.end.line, l:expression)
    else
      let l:before_line = getline(l:target_import.brace.end.line - 1)
      let l:indent = matchstr(l:before_line, '\m^\s*')
      call setline(l:target_import.brace.end.line - 1, l:before_line.',')
      call append(l:target_import.brace.end.line - 1, l:indent.l:block.identifier)
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
