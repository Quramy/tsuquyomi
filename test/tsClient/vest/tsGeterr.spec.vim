scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()
  let s:ver = tsuquyomi#config#getVersion()

  It checks interface of responce of 'geterr' command.
    if s:ver.major == 2 && s:ver.minor < 8
      echo "This test is pending in between TypeScript 2.0 and 2.7. Please fix this test case!"
    else
      let file = s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/SimpleModule_writing.ts')
      call tsuquyomi#tsClient#tsOpen(file)
      let files = [file]
      let result_list = tsuquyomi#tsClient#tsGeterr(files, 10)
      Should len(result_list) == 3
      let semanticDiagDict = filter(copy(result_list), 'v:val.event == "semanticDiag"')[0].body
      let syntaxDiagDict = filter(copy(result_list), 'v:val.event == "syntaxDiag"')[0].body
      Should has_key(semanticDiagDict, 'diagnostics')
      Should has_key(semanticDiagDict, 'file')
      Should len(semanticDiagDict.diagnostics) > 0
      Should has_key(semanticDiagDict.diagnostics[0], 'text')
      Should has_key(semanticDiagDict.diagnostics[0], 'start')
      Should has_key(semanticDiagDict.diagnostics[0].start, 'line')
      Should has_key(semanticDiagDict.diagnostics[0].start, 'offset')
      Should has_key(semanticDiagDict.diagnostics[0], 'end')
      Should has_key(semanticDiagDict.diagnostics[0].end, 'line')
      Should has_key(semanticDiagDict.diagnostics[0].end, 'offset')
      call tsuquyomi#tsClient#stopTssSync()
    endif
  End
End
Fin

