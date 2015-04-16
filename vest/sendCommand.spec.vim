
scriptencoding utf-8

Context Vesting.run()

  It checks to sendCommandOneWay successfully
    Should tsuquyomi#tsClient#sendCommandOneWay('open', {'file': 'myApp.ts'}) == []
    call tsuquyomi#tsClient#stopTss()
  End

  It checks to sendCommandSyncResponse successfully
    let res_list = tsuquyomi#tsClient#sendCommandSyncResponse('completions', {})
    Should len(res_list) == 1
    call tsuquyomi#tsClient#stopTss()
  End

  It checks to sendCommandSyncResponse successfully
    let res_list = tsuquyomi#tsClient#sendCommandSyncEvents('geterr', {'files': ['hoge'], 'delay': 50}, 0.01, 0)
    Should len(res_list) == 0
    call tsuquyomi#tsClient#stopTss()
  End

End
Fin
