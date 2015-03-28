scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsReferences] tsReferences

let g:tsuquyomi_use_dev_node_module=1
let g:tsuquyomi_waittime_after_open=0.2

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

function! s:test1()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/SimpleModule.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_list = tsuquyomi#tsClient#tsReferences(l:file, 10, 5) 
  echo res_list
  call tsuquyomi#tsClient#stopTss()
endfunction

