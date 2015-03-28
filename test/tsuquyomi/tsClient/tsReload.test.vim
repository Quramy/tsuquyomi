scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsReload] tsReload

let g:tsuquyomi_use_dev_node_module = 1
let g:tsuquyomi_waittime_after_open = 0.2

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

function! s:test1()
  let file = s:Filepath.join(s:script_dir, 'test/resouces/SimpleModuleFile.ts')
  call tsuquyomi#tsClient#tsOpen(file)
  echo tsuquyomi#tsClient#tsReload(file, file) == []
  call tsuquyomi#tsClient#stopTss()
endfunction
