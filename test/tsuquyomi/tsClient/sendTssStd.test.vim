scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#sendTssStd] sendTssStd
let g:tsuquyomi_use_dev_node_module = 1

function! s:test1()
  Assert tsuquyomi#tsClient#sendTssStd('{"command": "open", "arguments": { "file": "hoge.ts"}}', 0.01) == []
  call tsuquyomi#tsClient#stopTss()
endfunction
