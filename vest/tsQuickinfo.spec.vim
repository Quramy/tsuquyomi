scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'quickinfo' command.
    let file = s:Filepath.join(s:script_dir, 'vest/resources/SimpleModule.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let res_dict = tsuquyomi#tsClient#tsQuickinfo(file, 14, 13) 
    Should has_key(res_dict, 'start')
    Should has_key(res_dict.start, 'line')
    Should has_key(res_dict.start, 'offset')
    Should has_key(res_dict, 'end')
    Should has_key(res_dict.end, 'line')
    Should has_key(res_dict.end, 'offset')
    Should has_key(res_dict, 'displayString')
    Should has_key(res_dict, 'kind')
    Should has_key(res_dict, 'kindModifiers')
    Should res_dict.displayString == '(method) SimpleModule.MyClass.say(): string'
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin
