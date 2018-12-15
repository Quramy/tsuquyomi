scriptencoding utf-8

Context Vesting.run()
  It checks to sendRequest successfully
    let res = tsuquyomi#tsClient#sendRequest('{"command": "open", "arguments": { "file": "test/resrouces/SimpleModule.ts"}}', str2float("0.01"), 0, 0)
    Should res == []
    call tsuquyomi#tsClient#stopTssSync()
  End
End
Fin
