scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsGeterr] tsGeterr

let g:tsuquyomi_use_dev_node_module=1
let g:tsuquyomi_waittime_after_open=0.001

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

"TODO remove later
let g:tsuquyomi_use_dev_node_module = 2
let g:tsuquyomi_tsserver_path = s:Filepath.join(s:script_dir, '../../git/typescript/built/local/tsserver.js')

function! s:test1()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/SimpleModule_writing.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let files = [l:file]
  let result = tsuquyomi#tsClient#tsGeterr(files, 50)
  "echo result
  Assert has_key(result, 'syntaxDiag')
  Assert has_key(result, 'semanticDiag')
  Assert has_key(result.semanticDiag, 'diagnostics')
  Assert has_key(result.semanticDiag, 'file')
  Assert len(result.semanticDiag.diagnostics) > 0
  Assert has_key(result.semanticDiag.diagnostics[0], 'text')
  Assert has_key(result.semanticDiag.diagnostics[0], 'start')
  Assert has_key(result.semanticDiag.diagnostics[0].start, 'line')
  Assert has_key(result.semanticDiag.diagnostics[0].start, 'offset')
  Assert has_key(result.semanticDiag.diagnostics[0], 'end')
  Assert has_key(result.semanticDiag.diagnostics[0].end, 'line')
  Assert has_key(result.semanticDiag.diagnostics[0].end, 'offset')
  call tsuquyomi#tsClient#stopTss()
endfunction

