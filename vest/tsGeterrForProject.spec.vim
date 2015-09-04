scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'geterr' command.
    let file = s:Filepath.join(s:script_dir, 'vest/resources/samplePrjs/errorPrj/main.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let result_dict = tsuquyomi#tsClient#tsGeterrForProject(file, 10)
    echo result_dict
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin

