scriptencoding utf-8

Context Vesting.run()

  let s:V = vital#of('tsuquyomi')
  let s:Filepath = s:V.import('System.Filepath')
  let s:script_dir = tsuquyomi#rootDir()

  It checks interface of responce of 'signatureHelp' command.
    let file = substitute(s:Filepath.join(s:script_dir, 'vest/resources/signatureHelpTest_writing.ts'), '\\', '/', 'g')
    "echo l:file
    call tsuquyomi#tsClient#tsOpen(file)
    let res_signatureHelp_dict  = tsuquyomi#tsClient#tsSignatureHelp(file, 19, 12) 
    "echo res_signatureHelp_dict
    Should has_key(res_signatureHelp_dict, 'selectedItemIndex')
    Should has_key(res_signatureHelp_dict, 'argumentCount')
    Should has_key(res_signatureHelp_dict, 'argumentIndex')
    Should has_key(res_signatureHelp_dict, 'applicableSpan')
    Should has_key(res_signatureHelp_dict.applicableSpan, 'start')
    Should has_key(res_signatureHelp_dict.applicableSpan.start, 'line')
    Should has_key(res_signatureHelp_dict.applicableSpan.start, 'offset')
    Should has_key(res_signatureHelp_dict.applicableSpan, 'end')
    Should has_key(res_signatureHelp_dict.applicableSpan.end, 'line')
    Should has_key(res_signatureHelp_dict.applicableSpan.end, 'offset')
    Should has_key(res_signatureHelp_dict, 'items')
    Should len(res_signatureHelp_dict.items)
    Should has_key(res_signatureHelp_dict.items[0], 'separatorDisplayParts')
    Should len(res_signatureHelp_dict.items[0].separatorDisplayParts)
    Should has_key(res_signatureHelp_dict.items[0].separatorDisplayParts[0], 'kind')
    Should has_key(res_signatureHelp_dict.items[0].separatorDisplayParts[0], 'text')
    Should has_key(res_signatureHelp_dict.items[0], 'parameters')
    Should len(res_signatureHelp_dict.items[0].parameters)
    Should has_key(res_signatureHelp_dict.items[0].parameters[0], 'isOptional')
    Should has_key(res_signatureHelp_dict.items[0].parameters[0], 'name')
    Should res_signatureHelp_dict.items[0].parameters[0].name == 'a'
    Should has_key(res_signatureHelp_dict.items[0].parameters[0], 'documentation')
    Should len(res_signatureHelp_dict.items[0].parameters[0].documentation)
    Should has_key(res_signatureHelp_dict.items[0].parameters[0].documentation[0], 'kind')
    Should has_key(res_signatureHelp_dict.items[0].parameters[0].documentation[0], 'text')
    Should res_signatureHelp_dict.items[0].parameters[0].documentation[0].text == 'A operand.'
    Should has_key(res_signatureHelp_dict.items[0].parameters[0], 'displayParts')
    Should len(res_signatureHelp_dict.items[0].parameters[0].displayParts)
    Should has_key(res_signatureHelp_dict.items[0].parameters[0].displayParts[0], 'kind')
    Should has_key(res_signatureHelp_dict.items[0].parameters[0].displayParts[0], 'text')
    Should has_key(res_signatureHelp_dict.items[0], 'prefixDisplayParts')
    Should len(res_signatureHelp_dict.items[0].prefixDisplayParts)
    Should has_key(res_signatureHelp_dict.items[0].prefixDisplayParts[0], 'kind')
    Should has_key(res_signatureHelp_dict.items[0].prefixDisplayParts[0], 'text')
    Should has_key(res_signatureHelp_dict.items[0], 'suffixDisplayParts')
    Should has_key(res_signatureHelp_dict.items[0].suffixDisplayParts[0], 'kind')
    Should has_key(res_signatureHelp_dict.items[0].suffixDisplayParts[0], 'text')
    Should has_key(res_signatureHelp_dict.items[0], 'documentation')
    Should len(res_signatureHelp_dict.items[0].documentation)
    Should has_key(res_signatureHelp_dict.items[0].documentation[0], 'kind')
    Should has_key(res_signatureHelp_dict.items[0].documentation[0], 'text')
    call tsuquyomi#tsClient#stopTss()
  End

  It returns two items when the method is overridden.
    let file = substitute(s:Filepath.join(s:script_dir, 'vest/resources/signatureHelpTest_overload.ts'), '\\', '/', 'g')
    "echo l:file
    call tsuquyomi#tsClient#tsOpen(file)
    let res_signatureHelp_dict  = tsuquyomi#tsClient#tsSignatureHelp(file, 9, 19) 
    "echo res_signatureHelp_dict
    Should len(res_signatureHelp_dict.items) == 2
    call tsuquyomi#tsClient#stopTss()
  End
End
Fin
 
