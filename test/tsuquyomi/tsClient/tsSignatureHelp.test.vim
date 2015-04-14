scriptencoding utf-8

UTSuite [tsuquyomi#tsClient#tsSignatureHelp] tsSignatureHelp

let g:tsuquyomi_use_dev_node_module=1
let g:tsuquyomi_waittime_after_open=0.1

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = tsuquyomi#rootDir()

function! s:test1()
  let l:file = substitute(s:Filepath.join(s:script_dir, 'test/resources/signatureHelpTest_writing.ts'), '\\', '/', 'g')
  "echo l:file
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_dict  = tsuquyomi#tsClient#tsSignatureHelp(l:file, 19, 12) 
  "echo res_dict
  Assert has_key(res_dict, 'selectedItemIndex')
  Assert has_key(res_dict, 'argumentCount')
  Assert has_key(res_dict, 'argumentIndex')
  Assert has_key(res_dict, 'applicableSpan')
  Assert has_key(res_dict.applicableSpan, 'start')
  Assert has_key(res_dict.applicableSpan.start, 'line')
  Assert has_key(res_dict.applicableSpan.start, 'offset')
  Assert has_key(res_dict.applicableSpan, 'end')
  Assert has_key(res_dict.applicableSpan.end, 'line')
  Assert has_key(res_dict.applicableSpan.end, 'offset')
  Assert has_key(res_dict, 'items')
  Assert len(res_dict.items)
  Assert has_key(res_dict.items[0], 'separatorDisplayParts')
  Assert len(res_dict.items[0].separatorDisplayParts)
  Assert has_key(res_dict.items[0].separatorDisplayParts[0], 'kind')
  Assert has_key(res_dict.items[0].separatorDisplayParts[0], 'text')
  Assert has_key(res_dict.items[0], 'parameters')
  Assert len(res_dict.items[0].parameters)
  Assert has_key(res_dict.items[0].parameters[0], 'isOptional')
  Assert has_key(res_dict.items[0].parameters[0], 'name')
  Assert res_dict.items[0].parameters[0].name == 'a'
  Assert has_key(res_dict.items[0].parameters[0], 'documentation')
  Assert len(res_dict.items[0].parameters[0].documentation)
  Assert has_key(res_dict.items[0].parameters[0].documentation[0], 'kind')
  Assert has_key(res_dict.items[0].parameters[0].documentation[0], 'text')
  Assert res_dict.items[0].parameters[0].documentation[0].text == 'A operand.'
  Assert has_key(res_dict.items[0].parameters[0], 'displayParts')
  Assert len(res_dict.items[0].parameters[0].displayParts)
  Assert has_key(res_dict.items[0].parameters[0].displayParts[0], 'kind')
  Assert has_key(res_dict.items[0].parameters[0].displayParts[0], 'text')
  Assert has_key(res_dict.items[0], 'prefixDisplayParts')
  Assert len(res_dict.items[0].prefixDisplayParts)
  Assert has_key(res_dict.items[0].prefixDisplayParts[0], 'kind')
  Assert has_key(res_dict.items[0].prefixDisplayParts[0], 'text')
  Assert has_key(res_dict.items[0], 'suffixDisplayParts')
  Assert has_key(res_dict.items[0].suffixDisplayParts[0], 'kind')
  Assert has_key(res_dict.items[0].suffixDisplayParts[0], 'text')
  Assert has_key(res_dict.items[0], 'documentation')
  Assert len(res_dict.items[0].documentation)
  Assert has_key(res_dict.items[0].documentation[0], 'kind')
  Assert has_key(res_dict.items[0].documentation[0], 'text')
  call tsuquyomi#tsClient#stopTss()
endfunction

function! s:test2()
  let l:file = substitute(s:Filepath.join(s:script_dir, 'test/resources/signatureHelpTest_overload.ts'), '\\', '/', 'g')
  "echo l:file
  call tsuquyomi#tsClient#tsOpen(l:file)
  let res_dict  = tsuquyomi#tsClient#tsSignatureHelp(l:file, 9, 19) 
  "echo res_dict
  Assert len(res_dict.items) == 2
  call tsuquyomi#tsClient#stopTss()
endfunction
