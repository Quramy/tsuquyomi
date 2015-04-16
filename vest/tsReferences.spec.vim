scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'references' command.
    let file = s:Filepath.join(s:script_dir, 'vest/resources/referencesTestA.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let res_reference_list = tsuquyomi#tsClient#tsReferences(file, 2, 16) 
    Should has_key(res_reference_list, 'refs')
    " res_reference_list.refs contains self definition.
    Should len(res_reference_list.refs) == 2
    Should has_key(res_reference_list.refs[0], 'file')
    Should has_key(res_reference_list.refs[0], 'isWriteAccess')
    Should has_key(res_reference_list.refs[0], 'lineText')
    Should has_key(res_reference_list.refs[0], 'start')
    Should has_key(res_reference_list.refs[0].start, 'line')
    Should has_key(res_reference_list.refs[0].start, 'offset')
    Should has_key(res_reference_list.refs[0], 'end')
    Should has_key(res_reference_list.refs[0].end, 'line')
    Should has_key(res_reference_list.refs[0].end, 'offset')
    Should has_key(res_reference_list, 'symbolName')
    Should res_reference_list.symbolName == 'SomeClass'
    Should has_key(res_reference_list, 'symbolDisplayString')
    call tsuquyomi#tsClient#stopTss()
  End

  It checks the reference from other files
    let fileA = s:Filepath.join(s:script_dir, 'vest/resources/referencesTestA.ts')
    let fileB = s:Filepath.join(s:script_dir, 'vest/resources/referencesTestB.ts')
    call tsuquyomi#tsClient#tsOpen(fileA)
    call tsuquyomi#tsClient#tsOpen(fileB)
    let res_reference_list = tsuquyomi#tsClient#tsReferences(fileA, 2, 16) 
    "echo res_reference_list
    Should has_key(res_reference_list, 'refs')
    " res_reference_list.refs contains self definition , fileA reference and fileB reference.
    Should len(res_reference_list.refs) == 3
    Should has_key(res_reference_list.refs[0], 'file')
    Should has_key(res_reference_list.refs[0], 'isWriteAccess')
    Should has_key(res_reference_list.refs[0], 'lineText')
    Should has_key(res_reference_list.refs[0], 'start')
    Should has_key(res_reference_list.refs[0].start, 'line')
    Should has_key(res_reference_list.refs[0].start, 'offset')
    Should has_key(res_reference_list.refs[0], 'end')
    Should has_key(res_reference_list.refs[0].end, 'line')
    Should has_key(res_reference_list.refs[0].end, 'offset')
    Should has_key(res_reference_list, 'symbolName')
    Should res_reference_list.symbolName == 'SomeClass'
    Should has_key(res_reference_list, 'symbolDisplayString')
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin
 
