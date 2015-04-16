scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'completionEntryDetails' command.
    let file = s:Filepath.join(s:script_dir, 'vest/resources/SimpleModule_writing.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let res_list = tsuquyomi#tsClient#tsCompletionEntryDetails(file, 19, 9, ['say', 'greeting'])
    Should len(res_list) == 2

    let display_texts = []
    for result in res_list
      let display = ''
      for part in result.displayParts
        let display = display.part.text
      endfor
      call add(display_texts, display)
    endfor
    Should display_texts[0] == '(method) SimpleModule.MyClass.say(): string'
    Should display_texts[1] == '(property) SimpleModule.MyClass.greeting: string'
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin
