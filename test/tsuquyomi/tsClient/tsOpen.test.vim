scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsOpen] tsOpen
let g:tsuquyomi_use_dev_node_module=1
let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

function! s:test1()
  let file = s:Filepath.join(s:script_dir, 'test/resouces/SimpleModuleFile.ts')
  Assert tsuquyomi#tsClient#tsOpen(file) == []
  call tsuquyomi#tsClient#stopTss()
endfunction
