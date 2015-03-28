scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsOpen] tsOpen
let g:tsuquyomi_use_dev_node_module=1
let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

"let g:tsuquyomi_use_dev_node_module=2
"let g:tsuquyomi_tsserver_path = s:Filepath.join(s:script_dir, '../../git/typescript/built/local/tsserver.js')

function! s:test1()
  let file = s:Filepath.join(s:script_dir, 'test/resouces/SimpleModuleFile.ts')
  Assert tsuquyomi#tsClient#tsOpen(file) == []
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test2()
  let file = '_INVALID_FILE_NAME'
  Assert tsuquyomi#tsClient#tsOpen(file) == []
  let res = tsuquyomi#tsClient#sendCommand('completions', {'file': '_INVALID_FILE_NAME', 'line': 1, 'offset': 1, 'prefix': ''})
  Assert len(res) == 1
  Assert res[0].success == 0
  call tsuquyomi#tsClient#stopTss()
endfunction
