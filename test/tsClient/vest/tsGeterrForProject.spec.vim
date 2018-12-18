scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()
  let s:ver = tsuquyomi#config#getVersion()

  It checks interface of responce of 'geterr' command.
    if (s:ver.major == 2 && s:ver.minor < 8) ||
    \  (s:ver.major == 3 && s:ver.minor == 2)
      echo "This test is pending in between TypeScript 2.0 and 2.7, or 3.2. Please fix this test case!"
    else
      let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/samplePrjs/errorPrj/main.ts')
      let sub_file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/samplePrjs/errorPrj/sub.ts')
      call tsuquyomi#tsClient#tsOpen(file)
      let result_list = tsuquyomi#tsClient#tsGeterrForProject(file, 10, 2)
      Should len(result_list) == 6
      Should sort(map(copy(result_list), 'v:val.body.file')) == [file, file, file, sub_file, sub_file, sub_file]
      call tsuquyomi#tsClient#stopTssSync()
    endif
  End
End
Fin

