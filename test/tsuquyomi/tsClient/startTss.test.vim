scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#startTss] startTss
let g:tsuquyomi_use_dev_node_module = 1

function! s:test1()
  call tsuquyomi#tsClient#startTss()
  Assert tsuquyomi#tsClient#statusTss() == 'reading'
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test2()
  call tsuquyomi#tsClient#startTss()
  call tsuquyomi#tsClient#stopTss()
  Assert tsuquyomi#tsClient#statusTss() == 'undefined'
endfunction
