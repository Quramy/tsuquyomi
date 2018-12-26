scriptencoding utf-8

Context Vesting.run()

  It checks TSServer's status after startTss.
    call tsuquyomi#tsClient#startTss()
    Should tsuquyomi#tsClient#statusTss() == 'run'
    call tsuquyomi#tsClient#stopTssSync()
  End

  It checks TSServer's status after stopTssSync
    call tsuquyomi#tsClient#startTss()
    call tsuquyomi#tsClient#startTss()
    call tsuquyomi#tsClient#stopTssSync()
    Should tsuquyomi#tsClient#statusTss() == 'dead'
  End

End
Fin
