scriptencoding utf-8

Context Vesting.run()
  It checks to sendRequest successfully
    let res = tsuquyomi#tsClient#sendRequest('{"command": "open", "arguments": { "file": "test/resrouces/SimpleModule.ts"}}', 0.01, 0, 0)
    Should res == []
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin
