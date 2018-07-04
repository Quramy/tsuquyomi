"============================================================================
" FILE: autoload/tsuquyomi/es6import.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:JSON = s:V.import('Web.JSON')

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
      let l:relative_path = s:removeTSExtensions(l:relative_path)
      if g:tsuquyomi_shortest_import_path == 1
        let l:path = s:getShortestImportPath(l:to, l:identifier, l:relative_path)
      elseif g:tsuquyomi_baseurl_import_path == 1
        let l:base_url_import_path = s:getBaseUrlImportPath(nav.file)
        let l:path = l:base_url_import_path != '' ? l:base_url_import_path : l:relative_path
      else
        let l:path = l:relative_path
      endif
      let l:importDict = {
            \ 'identifier': nav.name,
            \ 'path': l:path,
            \ 'nav': nav
            \ }
      call add(l:result_list, l:importDict)
    endif
  endfor

  if g:tsuquyomi_case_sensitive_imports == 1
    call filter(l:result_list, 'v:val.identifier ==# l:identifier')
  endif

  " Make the possible imports list unique per path
  let dictionary = {}
  for i in l:result_list
    let dictionary[i.path] = i
  endfor

  let l:unique_result_list = []

  if (exists('a:1'))
    let l:unique_result_list = sort(values(dictionary), a:1)
  else
    let l:unique_result_list = sort(values(dictionary))
  endif

  return l:unique_result_list
endfunction

function! s:removeTSExtensions(path)
  let l:path = a:path
  let l:path = substitute(l:path, '\.d\.ts$', '', '')
  let l:path = substitute(l:path, '\.ts$', '', '')
  let l:path = substitute(l:path, '\.tsx$', '', '')
  let l:path = substitute(l:path, '^@types/', '', '')
  let l:path = substitute(l:path, '/index$', '', '')
  return l:path
endfunction

function! s:getShortestImportPath(absolute_path, module_identifier, relative_path)
  let l:splitted_relative_path = split(a:relative_path, '/')
  if l:splitted_relative_path[0] == '..'
    let l:paths_to_visit = substitute(a:relative_path, '\.\.\/', '', 'g')
    let l:path_moves_to_do = len(split(l:paths_to_visit, '/'))
  else
    let l:path_moves_to_do = len(l:splitted_relative_path) - 1
  endif
  let l:shortened_path = l:splitted_relative_path[len(l:splitted_relative_path) - 1]
  let l:path_move_count = 0
  let l:splitted_absolute_path = split(a:absolute_path, '/')
  while l:path_move_count != l:path_moves_to_do
    let l:splitted_absolute_path = l:splitted_absolute_path[0:len(splitted_absolute_path) - 2]
    let l:shortened_path = s:getShortenedPath(l:splitted_absolute_path, l:shortened_path, a:module_identifier)
    let l:path_move_count += 1
  endwhile
    let l:shortened_path = substitute(l:shortened_path, '\[\/\]\*\[\index\]\*', '', 'g')
    if l:splitted_relative_path[0] == '.'
      return './' . s:getPathWithSkippedRoot(l:shortened_path)
    elseif l:splitted_relative_path[0] == '..'
      let l:count = 0
      let l:current = '..'
      let l:prefix = ''
      while l:current == '..' || l:count == len(l:splitted_relative_path) - 1
        let l:current = l:splitted_relative_path[l:count]
        if l:current == '..'
          let l:prefix = l:prefix . l:current . '/'
        endif
        let l:count += 1
      endwhile
      return l:prefix . s:getPathWithSkippedRoot(l:shortened_path)
    endif
    return l:shortened_path
endfunction

function! s:getPathWithSkippedRoot(path)
  return join(split(a:path, '/')[1:len(a:path) -1], '/')
endfunction

function! s:getShortenedPath(splitted_absolute_path, previous_shortened_path, module_identifier)
  let l:shortened_path = a:previous_shortened_path
  let l:absolute_path_to_search_in = '/' . join(a:splitted_absolute_path, '/') . '/'
  let l:found_module_reference = s:findExportingFileForModule(a:module_identifier, l:shortened_path, l:absolute_path_to_search_in)
  let l:current_directory_name = a:splitted_absolute_path[len(a:splitted_absolute_path) -1]
  let l:path_separator = '/'
  while l:found_module_reference != ''
    if l:found_module_reference == 'index'
      let l:found_module_reference = '[index]*'
      let l:path_separator = '[/]*'
    else 
      let l:path_separator = '/'
    endif
    let l:shortened_path = l:found_module_reference
    let l:found_module_reference = s:findExportingFileForModule(a:module_identifier, l:found_module_reference, l:absolute_path_to_search_in)
    if l:found_module_reference != ''
      let l:shortened_path = l:found_module_reference
    endif
  endwhile
  return l:current_directory_name . l:path_separator . l:shortened_path
endfunction

function! s:getBaseUrlImportPath(module_absolute_path)
  let [l:tsconfig, l:tsconfig_file_path] = s:getTsconfig(a:module_absolute_path)

  if empty(l:tsconfig) || l:tsconfig_file_path == ''
    return ''
  endif

  let l:project_root_path = fnamemodify(l:tsconfig_file_path, ':h').'/'
  " We assume that baseUrl is a path relative to tsconfig.json path.
  let l:base_url_config = has_key(l:tsconfig.compilerOptions, 'baseUrl') ? l:tsconfig.compilerOptions.baseUrl : '.'
  let l:base_url_path = simplify(l:project_root_path.l:base_url_config)

  return s:removeTSExtensions(substitute(a:module_absolute_path, l:base_url_path, '', ''))
endfunction

let s:tsconfig = {}
let s:tsconfig_file_path = ''

function! s:getTsconfig(module_absolute_path)
  if empty(s:tsconfig)
    let l:project_info = tsuquyomi#tsClient#tsProjectInfo(a:module_absolute_path, 0)

    if has_key(l:project_info, 'configFileName')
      let s:tsconfig_file_path = l:project_info.configFileName
    else
      echom '[Tsuquyomi] Cannot find project’s tsconfig.json to compute baseUrl import path.'
    endif

    let l:json = join(readfile(s:tsconfig_file_path),'')

    try
      let s:tsconfig = s:JSON.decode(l:json)
    catch
      echom '[Tsuquyomi] Cannot parse project’s tsconfig.json. Does it have comments?'
    endtry

  endif

  return [s:tsconfig, s:tsconfig_file_path]
endfunction

function! s:findExportingFileForModule(module, current_module_file, module_directory_path)
  execute 
        \"silent! noautocmd vimgrep /export\\s*\\({.*\\(\\s\\|,\\)"
        \. a:module 
        \."\\(\\s\\|,\\)*.*}\\|\\*\\)\\s\\+from\\s\\+\\(\\'\\|\\\"\\)\\.\\\/"
        \. substitute(a:current_module_file, '\/', '\\/', '') 
        \."[\\/]*\\(\\'\\|\\\"\\)[;]*/j "
        \. a:module_directory_path 
        \. "*.ts"
  redir => l:grep_result
  silent! clist
  redir END
  if l:grep_result =~ 'No Errors'
    return ''
  endif
  let l:raw_result = split(l:grep_result, ' ')[2]
  let l:raw_result = split(l:raw_result, ':')[0]
  let l:raw_result_parts = split(l:raw_result, '/')
  let l:extracted_file_name = l:raw_result_parts[len(l:raw_result_parts) -1 ]
  let l:extracted_file_name = s:removeTSExtensions(l:extracted_file_name)
  return l:extracted_file_name
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

let s:importable_module_list = []
function! tsuquyomi#es6import#moduleComplete(arg_lead, cmd_line, cursor_pos)
  return join(s:importable_module_list, "\n")
endfunction

function! tsuquyomi#es6import#selectModule()
  echohl String
  let l:selected_module = input('[Tsuquyomi] You can import from 2 or more modules. Select one : ', '', 'custom,tsuquyomi#es6import#moduleComplete')
  echohl none
  echo ' '
  if len(filter(copy(s:importable_module_list), 'v:val==#l:selected_module'))
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
    let s:importable_module_list = map(copy(l:list), 'v:val.path')
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

  if g:tsuquyomi_import_curly_spacing == 0
    let l:curly_spacing = ''
  else
    let l:curly_spacing = ' '
  end

  "Add import declaration
  if !len(l:same_path_import_list)
    if g:tsuquyomi_semicolon_import
      let l:semicolon = ';'
    else
      let l:semicolon = ''
    endif
    if g:tsuquyomi_single_quote_import
      let l:expression = "import {".l:curly_spacing.l:block.identifier.l:curly_spacing."} from '".l:block.path."'".l:semicolon
    else
      let l:expression = 'import {'.l:curly_spacing.l:block.identifier.l:curly_spacing.'} from "'.l:block.path.'"'.l:semicolon
    endif
    call append(l:module_end_line, l:expression)
  else
    let l:target_import = l:same_path_import_list[0]
    if l:target_import.is_oneliner
      let l:line = getline(l:target_import.brace.end.line)
      let l:injection_position = target_import.brace.end.offset - 2 - strlen(l:curly_spacing)
      let l:expression = l:line[0:l:injection_position].', '.l:block.identifier.l:curly_spacing.l:line[l:target_import.brace.end.offset - 1: -1]
      call setline(l:target_import.brace.end.line, l:expression)
    else
      let l:before_line = getline(l:target_import.brace.end.line - 1)
      let l:indent = matchstr(l:before_line, '\m^\s*')
      let l:before_has_trailing_comma = matchstr(l:before_line, ',\s*$')
      if l:before_has_trailing_comma !=# ''
        let l:prev_trailing_comma = ''
        let l:new_trailing_comma = ','
      else
        let l:prev_trailing_comma = ','
        let l:new_trailing_comma = ''
      endif

      call setline(l:target_import.brace.end.line - 1, l:before_line.l:prev_trailing_comma)
      call append(l:target_import.brace.end.line - 1, l:indent.l:block.identifier.l:new_trailing_comma)
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
