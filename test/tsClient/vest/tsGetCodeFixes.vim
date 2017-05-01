scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'getSupportedCodeFixes' command.
    let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/codeFixTest.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let result_list = tsuquyomi#tsClient#tsGetCodeFixes(file, 6, 5, 6, 5, [2377])
    " echo result_list
    Should len(result_list)
    Should has_key(result_list[0], 'changes')
    Should len(result_list[0].changes)
    Should has_key(result_list[0].changes[0], 'textChanges')
    Should len(result_list[0].changes[0].textChanges)
    Should result_list[0].changes[0].textChanges[0].newText =~ 'super();'
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin
