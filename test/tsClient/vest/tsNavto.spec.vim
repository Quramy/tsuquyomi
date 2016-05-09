scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'navbar' command.
    let file = substitute(s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/SimpleModule.ts'), '\\', '/', 'g')
    call tsuquyomi#tsClient#tsOpen(file)
    let res_list = tsuquyomi#tsClient#tsNavto(file, 'encodeURIComponent', 100)
    " echo res_list
    Should len(res_list) > 0
    Should has_key(res_list[0], 'file')
    Should has_key(res_list[0], 'name')
    Should res_list[0].name == 'encodeURIComponent'
    Should has_key(res_list[0], 'kind')
    Should res_list[0].kind == 'function'
    Should has_key(res_list[0], 'matchKind')
    Should res_list[0].matchKind == 'exact'
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin
