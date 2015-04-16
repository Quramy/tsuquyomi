scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'reload' command.
    let file = s:Filepath.join(s:script_dir, 'vest/resources/SimpleModule.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    Should tsuquyomi#tsClient#tsReload(file, file) == 1
    call tsuquyomi#tsClient#stopTss()
    End
End
Fin
 
