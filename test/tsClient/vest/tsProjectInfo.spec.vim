scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of response of 'projectInfo' command
    let file = substitute(s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/samplePrjs/prj001/main.ts'), '\\', '/', 'g')
    call tsuquyomi#tsClient#tsOpen(file)
    let res_projectInfo_dict = tsuquyomi#tsClient#tsProjectInfo(file, 1)
    Should has_key(res_projectInfo_dict, 'configFileName')
    Should has_key(res_projectInfo_dict, 'fileNames')
    call tsuquyomi#tsClient#stopTss()
  End

End
Fin
