scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#sendCommand] sendCommand
let g:tsuquyomi_use_dev_node_module=1

function! s:test1()
  Assert tsuquyomi#tsClient#sendCommand('open', {'file': 'myApp.ts'}) == []
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test2()
  let l:res_list = tsuquyomi#tsClient#sendCommand('invalid', {})
  Assert len(l:res_list) == 2
  Assert l:res_list[0].command == 'unknown'
endfunction
