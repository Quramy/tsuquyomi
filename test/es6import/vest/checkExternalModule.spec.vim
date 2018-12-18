scriptencoding utf-8

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = s:Filepath.join(tsuquyomi#rootDir(), 'test/es6import/vest')

" FIXME
" Context tsuquyomi#es6import#checkExternalModule(moduleName, file, no_use_cache)
"   let s:input_file = s:Filepath.join(s:script_dir, 'resources/variousModules.d.ts')
" 
"   It returns 0 when the file does not have the given module
"     call tsuquyomi#tsClient#tsOpen(s:input_file)
"     let code = tsuquyomi#es6import#checkExternalModule('__NO_MODULE__', s:input_file, 1)
"     Should code == 0
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
"   It returns 1 when the file has single-quated module
"     call tsuquyomi#tsClient#tsOpen(s:input_file)
"     let code = tsuquyomi#es6import#checkExternalModule('external-module', s:input_file, 1)
"     Should code == 1
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
"   It returns 1 when the file has a double-quated module
"     call tsuquyomi#tsClient#tsOpen(s:input_file)
"     let code = tsuquyomi#es6import#checkExternalModule('external-module/alt', s:input_file, 1)
"     Should code == 1
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
"   It returns 0 when the file has a namespace
"     call tsuquyomi#tsClient#tsOpen(s:input_file)
"     let code = tsuquyomi#es6import#checkExternalModule('NS', s:input_file, 1)
"     Should code == 0
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
"   It returns 0 when the file has an internal module
"     call tsuquyomi#tsClient#tsOpen(s:input_file)
"     let code = tsuquyomi#es6import#checkExternalModule('InternalModule', s:input_file, 1)
"     Should code == 0
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
" End
