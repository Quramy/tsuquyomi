scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsQuickinfo] tsQuickinfo

let g:tsuquyomi_use_dev_node_module=0
let g:tsuquyomi_waittime_after_open=0.000001

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

"TODO remove later
"let g:tsuquyomi_use_dev_node_module = 2
"let g:tsuquyomi_tsserver_path = s:Filepath.join(s:script_dir, '../../git/typescript/built/local/tsserver.js')

function! s:test1()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/SimpleModule.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_dict = tsuquyomi#tsClient#tsQuickinfo(l:file, 14, 13) 
  "echo res_dict
  Assert has_key(res_dict, 'start')
  Assert has_key(res_dict.start, 'line')
  Assert has_key(res_dict.start, 'offset')
  Assert has_key(res_dict, 'end')
  Assert has_key(res_dict.end, 'line')
  Assert has_key(res_dict.end, 'offset')
  Assert has_key(res_dict, 'displayString')
  Assert has_key(res_dict, 'kind')
  Assert has_key(res_dict, 'kindModifiers')
  Assert res_dict.displayString == '(method) SimpleModule.MyClass.say(): string'
  call tsuquyomi#tsClient#stopTss()
endfunction

