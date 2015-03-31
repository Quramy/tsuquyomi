scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#sendRequest] sendRequest 
let g:tsuquyomi_use_dev_node_module = 1

function! s:test1()
  let res = tsuquyomi#tsClient#sendRequest('{"command": "open", "arguments": { "file": "test/resrouces/SimpleModule.ts"}}', 0.01, 0, 0)
  Assert res == []
  call tsuquyomi#tsClient#stopTss()
endfunction
