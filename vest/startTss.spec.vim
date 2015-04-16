scriptencoding utf-8

Context Vesting.run()

  It checks TSServer's status after startTss.
    call tsuquyomi#tsClient#startTss()
    Should tsuquyomi#tsClient#statusTss() == 'reading'
    call tsuquyomi#tsClient#stopTss()
  End

  It checks TSServer's status after stopTss
    call tsuquyomi#tsClient#startTss()
    call tsuquyomi#tsClient#startTss()
    call tsuquyomi#tsClient#stopTss()
    Should tsuquyomi#tsClient#statusTss() == 'undefined'
  End

End
Fin
