scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'rename' command.
    let file = s:Filepath.join(s:script_dir, 'vest/resources/SimpleModule.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let result_rename_dict = tsuquyomi#tsClient#tsRename(file, 5, 16, 0, 0) 
    Should has_key(result_rename_dict, 'info')
    Should has_key(result_rename_dict.info, 'canRename')
    Should has_key(result_rename_dict.info, 'displayName')
    Should result_rename_dict.info.displayName == 'MyClass'
    Should has_key(result_rename_dict.info, 'fullDisplayName')
    Should has_key(result_rename_dict.info, 'kind')
    Should result_rename_dict.info.kind == 'class'
    Should has_key(result_rename_dict.info, 'triggerSpan')
    Should has_key(result_rename_dict.info.triggerSpan, 'start')
    Should has_key(result_rename_dict.info.triggerSpan, 'length')
    Should has_key(result_rename_dict, 'locs')
    Should len(result_rename_dict.locs) == 1
    Should has_key(result_rename_dict.locs[0], 'file')
    Should result_rename_dict.locs[0].file != 'vest/resources/SimpleModule.ts'
    Should stridx(result_rename_dict.locs[0].file, 'vest/resources/SimpleModule.ts')
    Should has_key(result_rename_dict.locs[0], 'locs')
    Should len(result_rename_dict.locs[0].locs) == 2
    Should has_key(result_rename_dict.locs[0].locs[0], 'start')
    Should has_key(result_rename_dict.locs[0].locs[0].start, 'line')
    Should has_key(result_rename_dict.locs[0].locs[0].start, 'offset')
    Should has_key(result_rename_dict.locs[0].locs[0], 'end')
    Should has_key(result_rename_dict.locs[0].locs[0].end, 'line')
    Should has_key(result_rename_dict.locs[0].locs[0].end, 'offset')
    call tsuquyomi#tsClient#stopTss()
  End

  It checks rename command within symbol occurred across multiple files.
    let fileA = s:Filepath.join(s:script_dir, 'vest/resources/referencesTestA.ts')
    let fileB = s:Filepath.join(s:script_dir, 'vest/resources/referencesTestB.ts')
    call tsuquyomi#tsClient#tsOpen(fileA)
    call tsuquyomi#tsClient#tsOpen(fileB)
    let result_rename_dict = tsuquyomi#tsClient#tsRename(fileA, 2, 16, 0, 0) 

    Should len(result_rename_dict.locs) == 2
    Should stridx(result_rename_dict.locs[0].file, 'vest/resources/referencesTestA.ts')
    Should stridx(result_rename_dict.locs[1].file, 'vest/resources/referencesTestB.ts')

    call tsuquyomi#tsClient#stopTss()
  End

  It can rename when a line has two symbols. Should to that the result is sorted by reverse order.
    let file = s:Filepath.join(s:script_dir, 'vest/resources/renameTest.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let result_rename_dict = tsuquyomi#tsClient#tsRename(file, 3, 9, 0, 0) 
    Should len(result_rename_dict.locs[0].locs) == 3
    Should result_rename_dict.locs[0].locs[0].start.line == 4
    Should result_rename_dict.locs[0].locs[0].start.offset == 13
    Should result_rename_dict.locs[0].locs[1].start.line == 3
    Should result_rename_dict.locs[0].locs[1].start.offset == 25 
    Should result_rename_dict.locs[0].locs[2].start.line == 3
    Should result_rename_dict.locs[0].locs[2].start.offset == 9 
    call tsuquyomi#tsClient#stopTss()
  End

  It can rename variables in comments.
    let file = s:Filepath.join(s:script_dir, 'vest/resources/renameTest.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let result_rename_dict = tsuquyomi#tsClient#tsRename(file, 11, 21, 1, 0) 
    Should len(result_rename_dict.locs[0].locs) == 2
    Should result_rename_dict.locs[0].locs[1].start.line == 8
    Should result_rename_dict.locs[0].locs[1].start.offset == 15 
  End

  " It can rename identifiers in strings.
  "   let file = s:Filepath.join(s:script_dir, 'vest/resources/renameTest.ts')
  "   call tsuquyomi#tsClient#tsOpen(file)
  "   let result_rename_dict = tsuquyomi#tsClient#tsRename(file, 14, 13, 0, 1) 
  "   Should len(result_rename_dict.locs[0].locs) == 4
  " End

End
Fin
