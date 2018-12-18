scriptencoding utf-8

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = s:Filepath.join(tsuquyomi#rootDir(), 'test/es6import/vest')

" FIXME
" Context tsuquyomi#es6import#getImportDeclarations(file)
"   let s:resource_dir = s:Filepath.join(s:script_dir, 'resources/importDecPatterns')
" 
"   " It returns 'no_nav_bar' reason when input files is empty
"   "   let s:file = s:Filepath.join(s:resource_dir, 'empty.ts')
"   "   call tsuquyomi#tsClient#tsOpen(s:file)
"   "   let [result_list, position, reason] = tsuquyomi#es6import#getImportDeclarations(s:file, readfile(s:file))
"   "   Should reason ==# 'no_module_info'
"   "   call tsuquyomi#tsClient#stopTssSync()
"   " End
" 
"   " It returns 'no_module_info' reason and position info when input file doesn't have aliases
"   "   let s:file = s:Filepath.join(s:resource_dir, 'noDec.ts')
"   "   call tsuquyomi#tsClient#tsOpen(s:file)
"   "   let [result_list, position, reason] = tsuquyomi#es6import#getImportDeclarations(s:file, readfile(s:file))
"   "   Should reason ==# 'no_module_info'
"   "   Should position.start.line == 1
"   "   Should position.end.line == 3
"   "   call tsuquyomi#tsClient#stopTssSync()
"   " End
" 
"   It returns position when input file has import declaration and other declarations
"     let s:file = s:Filepath.join(s:resource_dir, 'decAndOther.ts')
"     call tsuquyomi#tsClient#tsOpen(s:file)
"     let [result_list, position, reason] = tsuquyomi#es6import#getImportDeclarations(s:file, readfile(s:file))
"     Should reason ==# ''
"     Should position.start.line == 1
"     Should position.end.line == 1
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
"   It returns position when input file has import declaration and expression
"     let s:file = s:Filepath.join(s:resource_dir, 'decAndFunction.ts')
"     call tsuquyomi#tsClient#tsOpen(s:file)
"     let [result_list, position, reason] = tsuquyomi#es6import#getImportDeclarations(s:file, readfile(s:file))
"     Should reason ==# ''
"     Should position.start.line == 1
"     Should position.end.line == 1
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
"   It returns declaration_info list
"     let s:file = s:Filepath.join(s:resource_dir, 'simple.ts')
"     call tsuquyomi#tsClient#tsOpen(s:file)
"     let [result_list, position, reason] = tsuquyomi#es6import#getImportDeclarations(s:file, readfile(s:file))
"     Should reason ==# ''
"     Should position.start.line == 1
"     Should position.end.line == 1
"     Should len(result_list) == 1
"     Should result_list[0].is_oneliner == 1
"     Should result_list[0].module.name ==# './some-module'
"     Should result_list[0].module.start.line == 1
"     Should result_list[0].module.end.line == 1
"     Should result_list[0].has_brace == 1
"     Should result_list[0].brace.end.line == 1
"     Should result_list[0].brace.end.offset == 18
"     Should result_list[0].has_from == 1
"     Should result_list[0].from_span.start.offset == 20 
"     Should result_list[0].from_span.start.line == 1
"     Should result_list[0].from_span.end.offset == 23 
"     Should result_list[0].from_span.end.line == 1
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
"   It returns a info whose 'is_oneliner' is 0 when input declaration contains multipule lines
"     let s:file = s:Filepath.join(s:resource_dir, 'multiline.ts')
"     call tsuquyomi#tsClient#tsOpen(s:file)
"     let [result_list, position, reason] = tsuquyomi#es6import#getImportDeclarations(s:file, readfile(s:file))
"     Should reason ==# ''
"     Should position.start.line == 1
"     Should position.end.line == 7
"     Should result_list[0].is_oneliner == 0
"     Should result_list[0].module.start.line == 7
"     Should result_list[0].module.end.line == 7
"     Should result_list[0].has_brace == 1
"     Should result_list[0].brace.end.line == 3
"     Should result_list[0].brace.end.offset == 13
"     Should result_list[0].has_from == 1
"     Should result_list[0].from_span.start.offset == 1
"     Should result_list[0].from_span.start.line == 5
"     Should result_list[0].from_span.end.offset == 4
"     Should result_list[0].from_span.end.line == 5
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
"   It returns the list whoes has multiple module infos when input declaration contains multiple aliases in one module
"     let s:file = s:Filepath.join(s:resource_dir, 'multiAlias.ts')
"     call tsuquyomi#tsClient#tsOpen(s:file)
"     let [result_list, position, reason] = tsuquyomi#es6import#getImportDeclarations(s:file, readfile(s:file))
"     Should len(result_list) == 2
"     Should result_list[0].alias_info.text ==# 'altVar'
"     Should result_list[1].alias_info.text ==# 'someVar'
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
"   It returns the list whoes has multiple module infos when input has 2 declaration
"     let s:file = s:Filepath.join(s:resource_dir, 'multiDec.ts')
"     call tsuquyomi#tsClient#tsOpen(s:file)
"     let [result_list, position, reason] = tsuquyomi#es6import#getImportDeclarations(s:file, readfile(s:file))
"     Should len(result_list) == 2
"     Should result_list[0].alias_info.text ==# 'altVar'
"     Should result_list[1].alias_info.text ==# 'someVar'
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
"   It returns explict alias info when declarations use 'as' keyword
"     let s:file = s:Filepath.join(s:resource_dir, 'explictAlias.ts')
"     call tsuquyomi#tsClient#tsOpen(s:file)
"     let [result_list, position, reason] = tsuquyomi#es6import#getImportDeclarations(s:file, readfile(s:file))
"     Should len(result_list) == 2
"     Should result_list[0].alias_info.text ==# '$var'
"     Should result_list[0].has_brace == 0
"     Should result_list[1].alias_info.text ==# '_var'
"     Should result_list[1].has_brace == 1
"     call tsuquyomi#tsClient#stopTssSync()
"   End
" 
" End
