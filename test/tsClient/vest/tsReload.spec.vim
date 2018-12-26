scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()
  let s:ver = tsuquyomi#config#getVersion()

  It checks interface of responce of 'reload' command.
    if v:true
      echo 'this test fails with all TypeScript versions. Please fix this test!'
    else
      let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/SimpleModule.ts')
      call tsuquyomi#tsClient#tsOpen(file)
      Should tsuquyomi#tsClient#tsReload(file, file) == 1
      call tsuquyomi#tsClient#stopTssSync()
    endif
    End
  End
Fin
 
