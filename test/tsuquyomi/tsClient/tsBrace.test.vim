scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsBrace] tsBrace

let g:tsuquyomi_use_dev_node_module=1
let g:tsuquyomi_waittime_after_open=0.2

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

function! s:test1()
  let l:file = s:Filepath.join(s:script_dir, 'test/resouces/SimpleModuleFile.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_list = tsuquyomi#tsClient#tsBrace(l:file, 2, 20) 
  Assert len(res_list) == 1
  echo tsuquyomi#tsClient#tsBrace(l:file, 1, 20) 
  echo tsuquyomi#tsClient#tsBrace(l:file, 5, 3) 
  echo tsuquyomi#tsClient#tsBrace(l:file, 11, 19) 
  call tsuquyomi#tsClient#stopTss()
endfunction
