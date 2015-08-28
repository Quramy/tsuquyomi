"============================================================================
" FILE: perfLogger.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:log_buffer = []
let s:start_time = reltime()

function! tsuquyomi#perfLogger#reset()
  let s:log_buffer = []
  let s:start_time = reltime()
endfunction

function! tsuquyomi#perfLogger#getTime()
  let num_row = len(s:log_buffer)
  let j = len(s:log_buffer) - num_row + 1
  while j < num_row
    let t = s:log_buffer[j]
    let prev = s:log_buffer[j - 1]
    echo reltimestr(t.elapse) t.name reltimestr(reltime(prev.elapse, t.elapse))
    let j = j + 1
  endwhile
endfunction

function! tsuquyomi#perfLogger#record(event_name)
  if g:tsuquyomi_debug
    call add(s:log_buffer, {'name': a:event_name, 'elapse': reltime(s:start_time)})
  endif
endfunction

