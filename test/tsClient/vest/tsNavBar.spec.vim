scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()
  let s:ver = tsuquyomi#config#getVersion()

  It checks interface of responce of 'navbar' command.
    if s:ver.major == 3 && s:ver.minor == 2
      echo "This test is pending on TypeScript 3.2. Please fix this test case!"
    else
      let file = substitute(s:Filepath.join(s:script_dir, 'test/tsClient/vest/resources/SimpleModule.ts'), '\\', '/', 'g')
      call tsuquyomi#tsClient#tsOpen(file)
      let res_list = tsuquyomi#tsClient#tsNavBar(file)
      " echo res_list
      Should len(res_list) > 0
      Should has_key(res_list[1], 'text')
      Should res_list[1].text == 'SimpleModule'
      Should has_key(res_list[1], 'kind')
      Should res_list[1].kind == 'module'
      Should has_key(res_list[1], 'kindModifiers')
      Should has_key(res_list[1], 'spans')
      Should len(res_list[1].spans) > 0
      Should has_key(res_list[1].spans[0], 'start')
      Should has_key(res_list[1].spans[0].start, 'line')
      Should has_key(res_list[1].spans[0].start, 'offset')
      Should has_key(res_list[1].spans[0], 'end')
      Should has_key(res_list[1].spans[0].end, 'line')
      Should has_key(res_list[1].spans[0].end, 'offset')
      Should has_key(res_list[1], 'childItems')
      Should len(res_list[1].childItems) > 0
      call tsuquyomi#tsClient#stopTssSync()
    endif
  End
End
Fin
