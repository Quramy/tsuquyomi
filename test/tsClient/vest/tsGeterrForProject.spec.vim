scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'geterr' command.
    let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/samplePrjs/errorPrj/main.ts')
    let sub_file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/samplePrjs/errorPrj/sub.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let result_list = tsuquyomi#tsClient#tsGeterrForProject(file, 10, 2)
    Should len(result_list) == 4
    Should sort(map(copy(result_list), 'v:val.body.file')) == [file, file, sub_file, sub_file]
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin

