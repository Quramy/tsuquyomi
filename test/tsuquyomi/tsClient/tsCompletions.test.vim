scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsCompletions] tsCompletions

let g:tsuquyomi_use_dev_node_module=1
let g:tsuquyomi_waittime_after_open=0.2

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

function! s:test1()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/SimpleModule.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_list = tsuquyomi#tsClient#tsCompletions(l:file, 17, 0, 'classDe') 
  Assert len(res_list) == 1
  Assert res_list[0].name == 'classDecorator'
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test2()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/SimpleModule_writing.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_list = tsuquyomi#tsClient#tsCompletions(l:file, 19, 9, 'say') 
  echo res_list
  "Assert len(res_list) == 1
  "Assert res_list[0].name == 'classDecorator'
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test3()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/SimpleModule.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_list = tsuquyomi#tsClient#tsCompletions(l:file, 11, 0, 'NO_EXSIT_KEYWORD_XXXXXXX') 
  Assert len(res_list) == 0
  call tsuquyomi#tsClient#stopTss()
endfunction

