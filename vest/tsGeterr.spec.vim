scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'geterr' command.
    let file = s:Filepath.join(s:script_dir, 'vest/resources/SimpleModule_writing.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let files = [file]
    let result_dict = tsuquyomi#tsClient#tsGeterr(files, 10)
    "echo result_dict
    Should has_key(result_dict, 'syntaxDiag')
    Should has_key(result_dict, 'semanticDiag')
    Should has_key(result_dict.semanticDiag, 'diagnostics')
    Should has_key(result_dict.semanticDiag, 'file')
    Should len(result_dict.semanticDiag.diagnostics) > 0
    Should has_key(result_dict.semanticDiag.diagnostics[0], 'text')
    Should has_key(result_dict.semanticDiag.diagnostics[0], 'start')
    Should has_key(result_dict.semanticDiag.diagnostics[0].start, 'line')
    Should has_key(result_dict.semanticDiag.diagnostics[0].start, 'offset')
    Should has_key(result_dict.semanticDiag.diagnostics[0], 'end')
    Should has_key(result_dict.semanticDiag.diagnostics[0].end, 'line')
    Should has_key(result_dict.semanticDiag.diagnostics[0].end, 'offset')
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin

