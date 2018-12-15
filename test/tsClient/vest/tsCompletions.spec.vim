scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'completions' command.
    let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/SimpleModule.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let res_list = tsuquyomi#tsClient#tsCompletions(file, 17, 0, 'setT')
    Should len(res_list) == 1
    Should res_list[0].name == 'setTimeout'
    call tsuquyomi#tsClient#stopTssSync()
  End

  It checks interface of responce of 'completions' command with non-existing keyword.
    let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/SimpleModule.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let res_list = tsuquyomi#tsClient#tsCompletions(file, 11, 0, 'NO_EXSIT_KEYWORD_XXXXXXX') 
    Should len(res_list) == 0
    call tsuquyomi#tsClient#stopTssSync()
  End

End
Fin
