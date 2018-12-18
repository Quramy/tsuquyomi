scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()
  let s:ver = tsuquyomi#config#getVersion()

  It checks interface of responce of 'rename' command.
    if s:ver.major == 3
      echo "This test is pending in between TypeScript 3. Please fix this test case!"
    else
      let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/SimpleModule.ts')
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
      Should result_rename_dict.locs[0].file != 'test/tsClient/vest/resources/SimpleModule.ts'
      Should stridx(result_rename_dict.locs[0].file, 'test/tsClient/vest/resources/SimpleModule.ts')
      Should has_key(result_rename_dict.locs[0], 'locs')
      Should len(result_rename_dict.locs[0].locs) == 2
      Should has_key(result_rename_dict.locs[0].locs[0], 'start')
      Should has_key(result_rename_dict.locs[0].locs[0].start, 'line')
      Should has_key(result_rename_dict.locs[0].locs[0].start, 'offset')
      Should has_key(result_rename_dict.locs[0].locs[0], 'end')
      Should has_key(result_rename_dict.locs[0].locs[0].end, 'line')
      Should has_key(result_rename_dict.locs[0].locs[0].end, 'offset')
      call tsuquyomi#tsClient#stopTssSync()
    endif
  End

  It checks rename command within symbol occurred across multiple files.
    let fileA = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/referencesTestA.ts')
    let fileB = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/referencesTestB.ts')
    call tsuquyomi#tsClient#tsOpen(fileA)
    call tsuquyomi#tsClient#tsOpen(fileB)
    let result_rename_dict = tsuquyomi#tsClient#tsRename(fileA, 2, 16, 0, 0) 

    Should len(result_rename_dict.locs) == 2
    Should stridx(result_rename_dict.locs[0].file, 'test/tsClient/vest/resources/referencesTestA.ts')
    Should stridx(result_rename_dict.locs[1].file, 'test/tsClient/vest/resources/referencesTestB.ts')

    call tsuquyomi#tsClient#stopTssSync()
  End

  It can rename when a line has two symbols. Should to that the result is sorted by reverse order.
    if s:ver.major == 3
      echo "This test is pending in between TypeScript 3. Please fix this test case!"
    else
      let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/renameTest.ts')
      call tsuquyomi#tsClient#tsOpen(file)
      let result_rename_dict = tsuquyomi#tsClient#tsRename(file, 3, 9, 0, 0) 
      Should len(result_rename_dict.locs[0].locs) == 3
      Should result_rename_dict.locs[0].locs[0].start.line == 4
      Should result_rename_dict.locs[0].locs[0].start.offset == 13
      Should result_rename_dict.locs[0].locs[1].start.line == 3
      Should result_rename_dict.locs[0].locs[1].start.offset == 25 
      Should result_rename_dict.locs[0].locs[2].start.line == 3
      Should result_rename_dict.locs[0].locs[2].start.offset == 9 
      call tsuquyomi#tsClient#stopTssSync()
    endif
  End

  It can rename variables in comments.
    if (s:ver.major == 2 && (s:ver.minor == 4 || s:ver.minor == 5)) ||
    \  (s:ver.major == 3)
      echo "This test is pending in between TypeScript 2.4 and 2.5, or TypeScript 3. Please fix this test case!"
    else
      let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/renameTest.ts')
      call tsuquyomi#tsClient#tsOpen(file)
      let result_rename_dict = tsuquyomi#tsClient#tsRename(file, 11, 21, 1, 0) 
      Should len(result_rename_dict.locs[0].locs) == 2
      Should result_rename_dict.locs[0].locs[1].start.line == 8
      Should result_rename_dict.locs[0].locs[1].start.offset == 15 
    endif
  End

  " It can rename identifiers in strings.
  "   let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/renameTest.ts')
  "   call tsuquyomi#tsClient#tsOpen(file)
  "   let result_rename_dict = tsuquyomi#tsClient#tsRename(file, 14, 13, 0, 1) 
  "   Should len(result_rename_dict.locs[0].locs) == 4
  " End

End
Fin
