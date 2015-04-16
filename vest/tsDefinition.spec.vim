scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let b:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()
  let s:result = []

  It checks interface of responce of 'definition' command.
    let file = b:Filepath.join(s:script_dir, 'vest/resources/definitionTest.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let b:result= tsuquyomi#tsClient#tsDefinition(file, 2, 15) 
    Should len(b:result) == 1
    Should b:Filepath.basename(b:result[0].file) == 'definitionTest.ts'
    Should has_key(b:result[0], 'start') != 0 
    Should has_key(b:result[0].start, 'line')
    Should has_key(b:result[0].start, 'offset') != 0 
    Should has_key(b:result[0], 'end') != 0 
    Should has_key(b:result[0].end, 'line') != 0 
    Should has_key(b:result[0].end, 'offset') != 0 
    call tsuquyomi#tsClient#stopTss()
  End

  It checkes no definition at no symbol
    let file = b:Filepath.join(s:script_dir, 'vest/resources/definitionTest.ts')
    call tsuquyomi#tsClient#tsOpen(file)
    let b:result = tsuquyomi#tsClient#tsDefinition(file, 3, 1) 
    Should b:result == []
  End
End
Fin
