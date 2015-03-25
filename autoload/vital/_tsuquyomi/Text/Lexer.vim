let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = s:V.import('Prelude')
endfunction

function! s:_vital_depends() abort
  return ['Prelude']
endfunction

function! s:_list2dict(list) abort
  if s:Prelude.is_list(a:list)
    if len(a:list) < 2 | call s:_exception('too few arguments.') | endif
    if 2 < len(a:list) | call s:_exception('too many arguments.') | endif
    if ! s:Prelude.is_string(a:list[0]) | call s:_exception('element of list is not string.') | endif
    if ! s:Prelude.is_string(a:list[1]) | call s:_exception('element of list is not string.') | endif
    let tkn = { 'label' : a:list[0], 'regex' : a:list[1] }
    return tkn
  else
    call s:_exception('first argument is not list.')
  endif
endfunction

function! s:_exception(msg) abort
  throw printf('[Text.Lexer] %s', a:msg)
endfunction

let s:obj = { 'tokens' : [] }

function! s:obj.exec(string) dict abort
  let match_tokens = []
  let idx = 0
  while idx < len(a:string)
    let best_tkn = {}
    for tkn in self.tokens
      let matched_text = matchstr(a:string[(idx):],'^' . tkn.regex)
      if ! empty(matched_text)
        let best_tkn = s:token(tkn.label,matched_text,idx)
        break
      endif
    endfor
    if best_tkn == {}
      call s:_exception(printf('cannot match. col:%d',idx))
    else
      let idx += len(best_tkn.matched_text)
      let match_tokens += [best_tkn]
    endif
  endwhile
  return match_tokens
endfunction

function! s:lexer(patterns) abort
  let obj = deepcopy(s:obj)
  for e in a:patterns
    let obj.tokens += [(s:_list2dict(e))]
  endfor
  return obj
endfunction

function! s:token(label,matched_text,col) abort
  let obj = {}
  let obj['label'] = a:label
  let obj['matched_text'] = a:matched_text
  let obj['col'] = a:col
  return obj
endfunction

function! s:simple_parser(expr) abort
  echoerr 'Text.Lexer.simple_parser(expr) is obsolete. Use Text.Parser.parser() instead.'
  let obj = { 'expr' : a:expr, 'idx' : 0, 'tokens' : [] }
  function! obj.end() dict abort
    return len(self.expr) <= self.idx
  endfunction
  function! obj.next() dict abort
    if self.end()
      call s:_exception('Already end of tokens.')
    else
      return self.expr[self.idx]
    endif
  endfunction
  function! obj.next_is(label) dict abort
    return self.next().label ==# a:label
  endfunction
  " @vimlint(EVL104, 1, l:next)
  function! obj.consume() dict abort
    if ! self.end()
      let next = self.next()
      let self.idx += 1
    else
      call s:_exception('Already end of tokens.')
    endif
    return next
  endfunction
  " @vimlint(EVL104, 0, l:next)
  return deepcopy(obj)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
