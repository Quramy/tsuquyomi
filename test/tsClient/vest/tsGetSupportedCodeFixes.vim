scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()
  let s:ver = tsuquyomi#config#getVersion()

  It checks interface of responce of 'getSupportedCodeFixes' command.
    if s:ver.major == 2 && s:ver.minor == 0
      echo "This test is pending on TypeScript 2.0. Please fix this test case!"
    else
      let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/SimpleModule_writing.ts')
      call tsuquyomi#tsClient#tsOpen(file)
      let result_list = tsuquyomi#tsClient#tsGetSupportedCodeFixes()
      Should len(result_list)
      call tsuquyomi#tsClient#stopTssSync()
    endif
  End
End
Fin

