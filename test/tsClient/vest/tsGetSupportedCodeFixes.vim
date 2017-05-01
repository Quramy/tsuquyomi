scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'getSupportedCodeFixes' command.
    let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/SimpleModule_writing.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let result_list = tsuquyomi#tsClient#tsGetSupportedCodeFixes()
    Should len(result_list)
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin

