scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsNavBar] tsNavBar

let g:tsuquyomi_use_dev_node_module=0
let g:tsuquyomi_waittime_after_open=0.1

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

"TODO remove later
"let g:tsuquyomi_use_dev_node_module = 2
"let g:tsuquyomi_tsserver_path = s:Filepath.join(s:script_dir, '../../../../git/typescript/built/local/tsserver.js')

function! s:test1()
  let l:file = substitute(s:Filepath.join(s:script_dir, 'test/resources/SimpleModule.ts'), '\\', '/', 'g')
  "echo l:file
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_list = tsuquyomi#tsClient#tsNavBar(l:file)
  "echo res_list
  Assert len(res_list) > 0
  Assert has_key(res_list[0], 'text')
  Assert res_list[0].text == 'SimpleModule'
  Assert has_key(res_list[0], 'kind')
  Assert res_list[0].kind == 'module'
  Assert has_key(res_list[0], 'kindModifiers')
  Assert has_key(res_list[0], 'spans')
  Assert len(res_list[0].spans) > 0
  Assert has_key(res_list[0].spans[0], 'start')
  Assert has_key(res_list[0].spans[0].start, 'line')
  Assert has_key(res_list[0].spans[0].start, 'offset')
  Assert has_key(res_list[0].spans[0], 'end')
  Assert has_key(res_list[0].spans[0].end, 'line')
  Assert has_key(res_list[0].spans[0].end, 'offset')
  Assert has_key(res_list[0], 'childItems')
  Assert len(res_list[0].childItems) > 0
  call tsuquyomi#tsClient#stopTss()
endfunction
