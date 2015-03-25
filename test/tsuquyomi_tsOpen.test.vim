scriptencoding utf-8

let s:V = vital#of('tsuquyomi')
let s:A = s:V.import('Assertion')
let g:tsuquyomi_use_dev_node_module=1

call s:A.define('Assert', 1)

Assert tsuquyomi#tsOpen('hoge.ts')<=>{}

echo tsuquyomi#stopTss()
