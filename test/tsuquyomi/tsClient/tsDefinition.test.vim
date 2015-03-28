scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsDefinition] tsDefinition

let g:tsuquyomi_use_dev_node_module=1
let g:tsuquyomi_waittime_after_open=0.1

let g:tsuquyomi_nodejs_path = 'node'

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

function! s:test1()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/definitionTest.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let result = tsuquyomi#tsClient#tsDefinition(l:file, 2, 15) 
  Assert len(result) == 1
  Assert s:Filepath.basename(result[0].file) == 'definitionTest.ts'
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test2()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/definitionTest.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let result = tsuquyomi#tsClient#tsDefinition(l:file, 3, 1) 
  Assert result == []
endfunction
