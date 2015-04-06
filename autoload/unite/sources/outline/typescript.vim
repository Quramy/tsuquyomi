"============================================================================
" FILE: autoload/unite/sources/outline/typescript.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

" Tsuquyomi outline info for TypeScript.

function! unite#sources#outline#typescript#outline_info()
  return s:outline_info
endfunction

let s:Tree = unite#sources#outline#import('Tree')

let s:outline_info = {
      \ 'is_volatile': 1,
      \ 'auto_update': 0,
      \ 'highlight_rules': [
      \   {'name': 'package', 
      \     'pattern': '/\S\+\s\+:module/'},
      \   {'name': 'method', 
      \     'pattern': '/\S\+\s\+:\%(method\|call\|construct\)/'},
      \   {'name': 'id', 
      \     'pattern': '/\S\+\s\+:\%(var\|alias\)/'},
      \   {'name': 'expanded', 
      \     'pattern': '/\S\+\s\+:\%(property\|index\)/'},
      \   {'name': 'type', 
      \     'pattern': '/\S\+\s\+:\%(class\|interface\)/'}
      \   ]
      \ }

function! s:createHeadingFromNavitem(navitem)
  let heading = {}
  let heading.word = a:navitem.text."\t:".a:navitem.kind
  let heading.type = a:navitem.kind
  if has_key(a:navitem, 'spans') && len(a:navitem.spans)
    let heading.lnum = a:navitem.spans[0].start.line
  endif
  return heading
endfunction

function! s:createNodeRecursive(parent_node, navitem_list)
  for navitem in a:navitem_list
    let heading = s:createHeadingFromNavitem(navitem)
    call s:Tree.append_child(a:parent_node, heading)
    if has_key(navitem, 'childItems') && len(navitem.childItems)
      call s:createNodeRecursive(heading, navitem.childItems)
    endif
  endfor
  return a:parent_node
endfunction

function! s:outline_info.extract_headings(context)
  let root = s:Tree.new()

  " 1. Fetch navigation info from TSServer.
  let [navbar_list, is_success] = tsuquyomi#navBar()

  if is_success
    let root = s:createNodeRecursive(root, navbar_list)
  endif

  return root
endfunction

