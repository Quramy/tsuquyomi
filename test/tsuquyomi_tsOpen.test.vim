scriptencoding utf-8

let s:V = vital#of('tsuquyomi')
let s:A = s:V.import('Assertion')
let g:tsuquyomi_use_dev_node_module=1

call s:A.define('Assert', 1)

let s:script_dir = expand('<sfile>:p:h')
let s:Filepath = s:V.import('System.Filepath')
let s:SimpleModuleFile = s:Filepath.join(s:script_dir, '../test/resouces/SimpleModuleFile.ts')

Assert tsuquyomi#tsOpen('test/resources/SimpleModule.ts')<=>{}
call tsuquyomi#tsSaveto('test/resources/SimpleModule.ts', '.tmp.ts')
"Assert tsuquyomi#tsClose('test/resources/SimpleModuleFile.ts')<=>{}

echo tsuquyomi#stopTss()
