"============================================================================
" FILE: tsuquyomi.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" let s:script_dir = expand('<sfile>:p:h')
" 
let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = expand('<sfile>:p:h')
let s:root_dir = s:Filepath.join(s:script_dir, '../')

"
" ### Buffer local functions {{{
function! s:bGetTempfilename()
  if(b:tmpfilename)
    return b:tmpfilename
  else
    let b:tmpfilename = tempname()
    return b:tmpfilename
  endif
endfunction

function! s:bOpen()
  call tsuquyomi#tsClient#tsOpen(expand('%'))
  let b:is_opened = 1
endfunction

" ### Buffer local functions }}}

" ### Utilites {{{
function! s:error(msg)
  echom (a:msg)
  throw 'tsuquyomi: '.a:msg
endfunction

function! s:bufferToTmp()
  let l:bufname = expand('%')
  let l:fname = s:bGetTempfilename()
  let l:buflist = getbufline('%', 1, '$')
  call writefile(l:buflist, l:fname)
  return l:fname
endfunction

function! s:normalizePath(path)
  return substitute(a:path, '\\', '/', 'g')
endfunction

" Save current buffer to a temp file, and emit to reload TSServer.
" This function may be called for conversation with TSServer after user's change buffer.
function! s:flash()
  if b:is_dirty
    let l:fname = s:bufferToTmp()
    call tsuquyomi#tsClient#tsReload(expand('%'), l:fname)
    let b:is_dirty = 0
  endif
endfunction

" ### Utilites }}}

" ### Public functions {{{
"
function! tsuquyomi#rootDir()
  return s:root_dir
endfunction

function! tsuquyomi#isDirty()
  return b:is_dirty
endfunction

function! tsuquyomi#letDirty()
  let b:is_dirty = 1
endfunction

function! tsuquyomi#open()
  let l:fileName = expand('%')
  if l:fileName == ''
    " TODO
    return 0
  endif
  call s:bOpen()
  return 1
endfunction

function! tsuquyomi#close()
  let l:fileName = expand('%')
  if l:fileName == ''
    "TODO
    return 0
  endif
  call tsuquyomi#tsClient#tsClose(l:fileName)
  let b:is_opened = 0
  return 1
endfunction

function! tsuquyomi#reload()
  let l:fileName = expand('%')
  if l:fileName == ''
    " TODO
    return 0
  endif
  if b:is_opened
    call tsuquyomi#tsClient#tsReload(l:fileName, l:fileName)
  else
    call s:bOpen()
  endif
  let b:is_dirty = 0
  return 1
endfunction

function! tsuquyomi#dumpCurrent()
  let l:fileName = expand('%')
  if l:fileName == ''
    " TODO
    return 0
  endif
  call tsuquyomi#tsClient#tsSaveto(l:fileName, l:fileName.'.dump')
  return 1
endfunction

function! tsuquyomi#complete(findstart, base)
  let l:line_str = getline('.')
  let l:line = line('.')
  let l:offset = col('.')
  
  " search backwards for start of identifier (iskeyword pattern)
  let l:start = l:offset 
  while l:start > 0 && l:line_str[l:start-2] =~ "\\k"
    let l:start -= 1
  endwhile

  if(a:findstart)
    call s:flash()
    return l:start - 1
  else
    let l:res_dict = {'words': []}
    let l:res_list = tsuquyomi#tsClient#tsCompletions(expand('%'), l:line, l:start, a:base)
    echom len(l:res_list)
    for info in l:res_list
      call add(l:res_dict.words, info.name)
    endfor
    return l:res_dict
  endif
endfunction

function! tsuquyomi#definition()
  call s:flash()

  let l:file = s:normalizePath(expand('%'))
  let l:line = line('.')
  let l:offset = col('.')
  let l:res_list = tsuquyomi#tsClient#tsDefinition(l:file, l:line, l:offset)

  if(len(l:res_list) == 1)
    " If get result, go to the location.
    let l:info = l:res_list[0]
    if l:file == l:info.file
      " Same file
      call cursor(l:info.start.line, l:info.start.offset)
    else
      " If other file, split window
      execute 'split +call\ cursor('.l:info.start.line.','.l:info.start.offset.') '.l:info.file
    endif
  else
    " If don't get result, do nothing.
  endif
endfunction

function! tsuquyomi#references()
  call s:flash()

  let l:file = expand('%')
  let l:line = line('.')
  let l:offset = col('.')

  let l:res = tsuquyomi#tsClient#tsReferences(l:file, l:line, l:offset)
  if(has_key(l:res, 'refs') && len(l:res.refs) != 0)
    let l:location_list = []
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
      lwindow
    endif
  else
    echom 'Tsuquyomi References: Not found'
  endif
endfunction

" ### Public functions }}}

let &cpo = s:save_cpo
unlet s:save_cpo
