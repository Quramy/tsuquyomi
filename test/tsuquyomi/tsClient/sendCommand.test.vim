scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#sendCommand] sendCommand
let g:tsuquyomi_use_dev_node_module=1

function! s:test1()
  Assert tsuquyomi#tsClient#sendCommandOneWay('open', {'file': 'myApp.ts'}) == []
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test2()
  let l:res_list = tsuquyomi#tsClient#sendCommandSyncResponse('completions', {})
  Assert len(l:res_list) == 1
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test3()
  let l:res_list = tsuquyomi#tsClient#sendCommandSyncEvents('geterr', {'files': ['hoge'], 'delay': 50}, 0.01, 0)
  Assert len(l:res_list) == 0
  call tsuquyomi#tsClient#stopTss()
endfunction
