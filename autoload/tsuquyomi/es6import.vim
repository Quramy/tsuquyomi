"============================================================================
" FILE: tsuquyomi.vim
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

function! tsuquyomi#es6import#createImportBlock()
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

function!tsuquyomi#es6import#getImportList()
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
    echom '[Tsuquyomi] invalid module path.'
    echohl none
    return ['', 0]
  endif
endfunction

function! tsuquyomi#es6import#complete()
  let l:list = tsuquyomi#es6import#createImportBlock()
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
  let [l:import_list, l:module_end_line, l:reason] = tsuquyomi#es6import#getImportList()
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

let &cpo = s:save_cpo
unlet s:save_cpo