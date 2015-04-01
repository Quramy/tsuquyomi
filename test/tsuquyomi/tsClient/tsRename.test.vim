scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsRename] tsRename

let g:tsuquyomi_use_dev_node_module=1
let g:tsuquyomi_waittime_after_open=0.001

let g:tsuquyomi_nodejs_path = 'node'

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

"TODO remove later
let g:tsuquyomi_use_dev_node_module = 2
let g:tsuquyomi_tsserver_path = s:Filepath.join(s:script_dir, '../../git/typescript/built/local/tsserver.js')

function! s:test1()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/SimpleModule.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let result = tsuquyomi#tsClient#tsRename(l:file, 5, 16, 0, 0) 
  Assert has_key(result, 'info')
  Assert has_key(result.info, 'canRename')
  Assert has_key(result.info, 'displayName')
  Assert result.info.displayName == 'MyClass'
  Assert has_key(result.info, 'fullDisplayName')
  Assert has_key(result.info, 'kind')
  Assert result.info.kind == 'class'
  Assert has_key(result.info, 'triggerSpan')
  Assert has_key(result.info.triggerSpan, 'start')
  Assert has_key(result.info.triggerSpan, 'length')
  Assert has_key(result, 'locs')
  Assert len(result.locs) == 1
  Assert has_key(result.locs[0], 'file')
  Assert result.locs[0].file != 'test/resources/SimpleModule.ts'
  Assert stridx(result.locs[0].file, 'test/resources/SimpleModule.ts')
  Assert has_key(result.locs[0], 'locs')
  Assert len(result.locs[0].locs) == 2
  Assert has_key(result.locs[0].locs[0], 'start')
  Assert has_key(result.locs[0].locs[0].start, 'line')
  Assert has_key(result.locs[0].locs[0].start, 'offset')
  Assert has_key(result.locs[0].locs[0], 'end')
  Assert has_key(result.locs[0].locs[0].end, 'line')
  Assert has_key(result.locs[0].locs[0].end, 'offset')
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test2()
  " Symbol occurred across multiple files
  let l:fileA = s:Filepath.join(s:script_dir, 'test/resources/referencesTestA.ts')
  let l:fileB = s:Filepath.join(s:script_dir, 'test/resources/referencesTestB.ts')
  call tsuquyomi#tsClient#tsOpen(l:fileA)
  call tsuquyomi#tsClient#tsOpen(l:fileB)
  let result = tsuquyomi#tsClient#tsRename(l:fileA, 2, 16, 0, 0) 

  Assert len(result.locs) == 2
  Assert stridx(result.locs[0].file, 'test/resources/referencesTestA.ts')
  Assert stridx(result.locs[1].file, 'test/resources/referencesTestB.ts')

  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test3()
  " A line has two symbols. Assert to that the result is sorted by reverse order.
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/renameTest.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let result = tsuquyomi#tsClient#tsRename(l:file, 2, 7, 0, 0) 
  Assert len(result.locs[0].locs) == 4
  Assert result.locs[0].locs[0].start.line == 5
  Assert result.locs[0].locs[0].end.offset == 35
  Assert result.locs[0].locs[1].start.line == 5
  Assert result.locs[0].locs[1].end.offset == 15
  Assert result.locs[0].locs[2].start.line == 4
  Assert result.locs[0].locs[3].start.line == 2
  call tsuquyomi#tsClient#stopTss()
endfunction

