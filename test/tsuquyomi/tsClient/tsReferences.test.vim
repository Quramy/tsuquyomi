scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsReferences] tsReferences

let g:tsuquyomi_use_dev_node_module=1
let g:tsuquyomi_waittime_after_open=0.2

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

"TODO remove later
let g:tsuquyomi_use_dev_node_module = 2
let g:tsuquyomi_tsserver_path = s:Filepath.join(s:script_dir, '../../git/typescript/built/local/tsserver.js')

function! s:test1()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/referencesTestA.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_list = tsuquyomi#tsClient#tsReferences(l:file, 2, 16) 
  Assert has_key(res_list, 'refs')
  " res_list.refs contains self definition.
  Assert len(res_list.refs) == 2
  Assert has_key(res_list.refs[0], 'file')
  Assert has_key(res_list.refs[0], 'isWriteAccess')
  Assert has_key(res_list.refs[0], 'lineText')
  Assert has_key(res_list.refs[0], 'start')
  Assert has_key(res_list.refs[0].start, 'line')
  Assert has_key(res_list.refs[0].start, 'offset')
  Assert has_key(res_list.refs[0], 'end')
  Assert has_key(res_list.refs[0].end, 'line')
  Assert has_key(res_list.refs[0].end, 'offset')
  Assert has_key(res_list, 'symbolName')
  Assert res_list.symbolName == 'SomeClass'
  Assert has_key(res_list, 'symbolDisplayString')
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test2()
  let l:fileA = s:Filepath.join(s:script_dir, 'test/resources/referencesTestA.ts')
  let l:fileB = s:Filepath.join(s:script_dir, 'test/resources/referencesTestB.ts')
  call tsuquyomi#tsClient#tsOpen(l:fileA)
  call tsuquyomi#tsClient#tsOpen(l:fileB)
  let res_list = tsuquyomi#tsClient#tsReferences(l:fileA, 2, 16) 
  "echo res_list
  Assert has_key(res_list, 'refs')
  " res_list.refs contains self definition , fileA reference and fileB reference.
  Assert len(res_list.refs) == 3
  Assert has_key(res_list.refs[0], 'file')
  Assert has_key(res_list.refs[0], 'isWriteAccess')
  Assert has_key(res_list.refs[0], 'lineText')
  Assert has_key(res_list.refs[0], 'start')
  Assert has_key(res_list.refs[0].start, 'line')
  Assert has_key(res_list.refs[0].start, 'offset')
  Assert has_key(res_list.refs[0], 'end')
  Assert has_key(res_list.refs[0].end, 'line')
  Assert has_key(res_list.refs[0].end, 'offset')
  Assert has_key(res_list, 'symbolName')
  Assert res_list.symbolName == 'SomeClass'
  Assert has_key(res_list, 'symbolDisplayString')
  call tsuquyomi#tsClient#stopTss()
endfunction

