scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'navbar' command.
    let file = substitute(s:Filepath.join(s:script_dir, 'vest/resources/SimpleModule.ts'), '\\', '/', 'g')
    call tsuquyomi#tsClient#tsOpen(file)
    let res_list = tsuquyomi#tsClient#tsNavBar(file)
    "echo res_list
    Should len(res_list) > 0
    Should has_key(res_list[0], 'text')
    Should res_list[0].text == 'SimpleModule'
    Should has_key(res_list[0], 'kind')
    Should res_list[0].kind == 'module'
    Should has_key(res_list[0], 'kindModifiers')
    Should has_key(res_list[0], 'spans')
    Should len(res_list[0].spans) > 0
    Should has_key(res_list[0].spans[0], 'start')
    Should has_key(res_list[0].spans[0].start, 'line')
    Should has_key(res_list[0].spans[0].start, 'offset')
    Should has_key(res_list[0].spans[0], 'end')
    Should has_key(res_list[0].spans[0].end, 'line')
    Should has_key(res_list[0].spans[0].end, 'offset')
    Should has_key(res_list[0], 'childItems')
    Should len(res_list[0].childItems) > 0
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin
