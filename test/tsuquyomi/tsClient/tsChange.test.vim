scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsChange] tsChange
let g:tsuquyomi_use_dev_node_module= 1
let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

"TODO remove later
let g:tsuquyomi_use_dev_node_module = 2
let g:tsuquyomi_tsserver_path = s:Filepath.join(s:script_dir, '../../git/typescript/built/local/tsserver.js')

function! s:test1()
  let file = s:Filepath.join(s:script_dir, 'test/resources/SimpleModule.ts')
  call tsuquyomi#tsClient#tsOpen(file)
  call tsuquyomi#tsClient#tsChange(file, 18, 3, 18, 29, '')
  call tsuquyomi#tsClient#tsSaveto(file, s:Filepath.join(s:script_dir, '.tmp.ts'))
  call tsuquyomi#tsClient#stopTss()
endfunction

