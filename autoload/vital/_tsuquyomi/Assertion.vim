
let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:assert_config = {
        \   'equal_separator' : ['<=>','<=>'],
        \   'not_equal_separator' : ['<!>','<!>'],
        \   'enable' : 1,
        \ }
  let s:V = a:V
  let s:L = s:V.import('Text.Lexer')
  let s:lexer_obj = s:L.lexer([
        \ s:assert_config.equal_separator,
        \ s:assert_config.not_equal_separator,
        \ ['scriptfunc', 's:[0-9a-zA-Z_]\+'],
        \ ['ident', '[0-9a-zA-Z_]\+'],
        \ ['ws', '\s\+'],
        \ ['d_string', '"\(\\.\|[^"]\)*"'],
        \ ['s_string', '''\(''''\|[^'']\)*'''],
        \ ['otherwise', '.']
        \ ])
endfunction

function! s:_vital_depends() abort
  return ['Text.Lexer']
endfunction

function! s:_outputter(dict) abort
  if ! a:dict.is_success
    echohl Error
  endif
  echo  printf("%s %s :%s",
        \ a:dict.cmd,
        \ a:dict.expr,
        \ (a:dict.is_success ? 'Succeeded' : 'Failed'),
        \ )
  if ! a:dict.is_success
    echo  printf("> assert_point: %s", a:dict.assert_point)
    echo  printf("> lhs: %s", a:dict.lhs)
    echo  printf("> rhs: %s", a:dict.rhs)
    echohl None

    throw 'vital: Assertion: EXIT_FAILURE'
  endif
endfunction

function! s:_redir(cmd) abort
  let oldverbosefile = &verbosefile
  try
    set verbosefile=
    redir => res
    silent! execute a:cmd
    redir END
  finally
    let &verbosefile = oldverbosefile
  endtry
  return res
endfunction

function! s:_define_scriptfunction(fname) abort
  let scriptnames_list = map(split(s:_redir('scriptnames'),"\n"),'matchlist(v:val,''^\s*\(\d\+\)\s*:\s*\(.*\)\s*$'')[:2]')
  let targets = filter(copy(scriptnames_list),printf('fnamemodify(get(v:val,2,""),":p") ==# fnamemodify(%s,":p")',string(expand('%'))))
  if ! empty(targets)
    if exists(printf("*<SNR>%d_%s", targets[0][1], a:fname[2:]))
      execute printf('let %s = function(%s)',a:fname,string(printf("<SNR>%d_%s",targets[0][1],a:fname[2:])))
    endif
  endif
endfunction

function! s:_assertion( q_args, local, scriptfilename, about_currline, cmd) abort
  let s:_local = {}
  for s:_local.key in keys(a:local)
    execute printf('let %s = %s',s:_local.key,string(a:local[s:_local.key]))
  endfor
  if s:assert_config.enable
    let s:_local.tkns = s:lexer_obj.exec(a:q_args)
    let s:_local.is_lhs = 1
    let s:_local.is_not = 0
    let s:_local.lhs_tkns = []
    let s:_local.rhs_tkns  = []
    for s:_local.tkn in s:_local.tkns
      if s:_local.is_lhs && s:_local.tkn.label == s:assert_config.equal_separator[0]
        let s:_local.is_lhs = 0
        let s:_local.is_not = 0
      elseif s:_local.is_lhs && s:_local.tkn.label == s:assert_config.not_equal_separator[0]
        let s:_local.is_lhs = 0
        let s:_local.is_not = 1
      elseif s:_local.is_lhs
        let s:_local.lhs_tkns  += [s:_local.tkn]
      else
        let s:_local.rhs_tkns  += [s:_local.tkn]
      endif
      if s:_local.tkn.label ==# 'scriptfunc'
        call s:_define_scriptfunction(s:_local.tkn.matched_text)
      endif
    endfor

    let s:_local.lhs_text = join(map(s:_local.lhs_tkns ,'v:val.matched_text'),'')
    let s:_local.rhs_text = join(map(s:_local.rhs_tkns ,'v:val.matched_text'),'')
    let s:_local.is_success = 0
    if type("") == type(eval(s:_local.lhs_text))
      let s:_local.is_success = eval(s:_local.lhs_text) ==# eval(s:_local.rhs_text)
    else
      let s:_local.is_success = eval(s:_local.lhs_text) == eval(s:_local.rhs_text)
    endif

    let s:_local.is_success = s:_local.is_not ? ! s:_local.is_success : s:_local.is_success

    call s:_outputter({
          \ 'config' : copy(s:assert_config),
          \ 'cmd' : a:cmd,
          \ 'is_not' : s:_local.is_not,
          \ 'is_success' : s:_local.is_success,
          \ 'lhs' : s:_local.lhs_text,
          \ 'rhs' : s:_local.rhs_text,
          \ 'expr' : a:q_args,
          \ 'assert_point' : a:about_currline,
          \ })
  endif
endfunction

function! s:define(cmd_name,...) abort
  if (0 < len(a:000)) ? a:1 : 0
    execute 'command! -buffer -nargs=1 '.a:cmd_name.' try | throw 1 | catch | call s:_assertion(<q-args>,(exists(''l:'')?eval(''l:''):{}),expand(''%''), v:throwpoint, '.string(a:cmd_name).') | endtry'
  else
    execute 'command! -buffer -nargs=1 '.a:cmd_name
  endif
endfunction

function! s:set_config(config) abort
  " TODO
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

"  vim: set ts=2 sts=2 sw=2 ft=vim fdm=indent ff=unix expandtab:
