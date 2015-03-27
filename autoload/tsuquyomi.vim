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
" let s:P = s:V.import('ProcessManager')
" let s:JSON = s:V.import('Web.JSON')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = expand('<sfile>:p:h')
let s:root_dir = s:Filepath.join(s:script_dir, '../')
" let s:tsq = 'tsuquyomiTSServer'

" ### Utilites {{{
function! s:error(msg)
  echom (a:msg)
  throw 'tsuquyomi: '.a:msg
endfunction
" ### Utilites }}}

" ### Public functions {{{
"
function! tsuquyomi#rootDir()
  return s:root_dir
endfunction

function! tsuquyomi#open()
  let l:fileName = expand('%')
  if l:fileName == ''
    " TODO
    return 0
  endif
  call tsuquyomi#tsClient#tsOpen(l:fileName)
  return 1
endfunction

function! tsuquyomi#reload()
  let l:fileName = expand('%')
  if l:fileName == ''
    " TODO
    return 0
  endif
  call tsuquyomi#tsClient#tsReload(l:fileName, l:fileName)
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
    return l:start - 1
  else
    "echom a:base
    let l:res_dict = {'words': []}
    "let l:res_dict.words = ['aaa', 'bbbb']
    let l:res_list = tsuquyomi#tsClient#tsCompletions(expand('%'), l:line, l:start, a:base)
    echom len(l:res_list)
    for info in l:res_list
      call add(l:res_dict.words, info.name)
    endfor
    return l:res_dict
  endif
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

" ### Public functions }}}

let &cpo = s:save_cpo
unlet s:save_cpo
