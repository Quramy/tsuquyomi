scriptencoding utf-8

let s:V = vital#of('tsuquyomi')
let s:A = s:V.import('Assertion')
let g:tsuquyomi_use_dev_node_module=2
let g:tsuquyomi_tsserver_path='C:\\Users\nriuser\\git\\TypeScript\\bin\\tsserver.js'

call s:A.define('Assert', 1)

Assert tsuquyomi#sendCommand('open', {'file': 'myApp.ts'})<=>{}

echo tsuquyomi#stopTss()
echo tsuquyomi#statusTss()

