scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsDefinition] tsDefinition

let g:tsuquyomi_use_dev_node_module=1
let g:tsuquyomi_waittime_after_open=0.5

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

" TODO remove later.
let g:tsuquyomi_use_dev_node_module=2
let g:tsuquyomi_tsserver_path = s:Filepath.join(s:script_dir, '../../git/typescript/built/local/tsserver.js')

function! s:test1()
  let l:file = s:Filepath.join(s:script_dir, 'test/resouces/SimpleModuleFile.ts')
  "let l:file = s:Filepath.join(s:script_dir, 'node_modules/typescript/src/server/server.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  "call tsuquyomi#tsClient#tsSaveto(l:file, s:Filepath.join(s:script_dir, '.tmp.ts'))

  "let res_list = tsuquyomi#tsClient#tsDefinition(l:file, 18, 19) 
  "Assert len(res_list) == 1
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 1) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 2) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 3) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 4) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 5) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 6) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 7) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 8) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 9) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 10) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 19) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 20) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 21) 
  " echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 22) 
  "echo tsuquyomi#tsClient#tsDefinition(l:file, 1, 14) 
  "echo tsuquyomi#tsClient#tsDefinition(l:file, 18, 19) 
  call tsuquyomi#tsClient#tsSaveto(l:file, s:Filepath.join(s:script_dir, '.tmp.ts'))
  "echo tsuquyomi#tsClient#tsDefinition(l:file, 171, 18) 
  "echo tsuquyomi#tsClient#tsCompletions(l:file, 162, 1, 'fi') 
  call tsuquyomi#tsClient#stopTss()
endfunction
