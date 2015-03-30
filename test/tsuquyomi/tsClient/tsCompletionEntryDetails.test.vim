scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsCompletionEntryDetails] tsCompletionEntryDetails

let g:tsuquyomi_use_dev_node_module=1
let g:tsuquyomi_waittime_after_open=0.1

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

function! s:test1()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/SimpleModule_writing.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_list = tsuquyomi#tsClient#tsCompletionEntryDetails(l:file, 19, 9, ['say', 'greeting'])
  Assert len(res_list) == 2

  let display_texts = []
  for result in res_list
    Assert has_key(result, 'displayParts')
    let l:display = ''
    for part in result.displayParts
      let l:display = l:display.part.text
    endfor
    call add(display_texts, l:display)
  endfor
  Assert display_texts[0] == '(method) SimpleModule.MyClass.say(): string'
  Assert display_texts[1] == '(property) SimpleModule.MyClass.greeting: string'
  call tsuquyomi#tsClient#stopTss()
endfunction


function! s:test2()
  let l:file = s:Filepath.join(s:script_dir, 'test/resources/SimpleModule.ts')
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_list = tsuquyomi#tsClient#tsCompletionEntryDetails(l:file, 17, 1, ['DOMError'])
  Assert len(res_list) == 1
  echo res_list
  let display_texts = []
  for result in res_list
    Assert has_key(result, 'displayParts')
    let l:display = ''
    for part in result.displayParts
      if part.kind == 'lineBreak'
        let l:display = l:display.'{...}'
        break
      endif
      let l:display = l:display.part.text
    endfor
    call add(display_texts, l:display)
  endfor
  echo display_texts[0]
  call tsuquyomi#tsClient#stopTss()
endfunction


