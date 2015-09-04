"============================================================================
" FILE: autoload/unite/sources/tsproject.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

let s:source = {
      \ 'name': 'tsproject',
      \ 'is_grouped': 1,
      \ 'description': 'TypeScript project information',
      \ }

function! s:source.gather_candidates(args, context)
  if len(a:args)
    let selected_group_name = a:args[0]
  else
    let selected_group_name = '.'
  endif

  let buf_name = expand('%:p')
  let pinfo = tsuquyomi#projectInfo(buf_name)

  let result = []

  if has_key(pinfo, 'configFileName')
    call add(result, {
          \ 'group': 'tsconfig',
          \ 'kind': 'file',
          \ 'action__path': pinfo.configFileName,
          \ 'word': pinfo.configFileName,
          \ 'abbr': "\t".pinfo.configFileName,
          \ 'source': 'tsproject'
          \ })
  else
    call add(result, {
          \ 'group': 'tsconfig',
          \ 'kind': 'common',
          \ 'is_dummy': 1,
          \ 'word': '(your project does not have tsconfig.json)',
          \ 'abbr': "\t(your project does not have tsconfig.json)",
          \ 'source': 'tsproject'
          \ })
  endif

  if has_key(pinfo, 'filteredFileNames')
    for fileName in sort(copy(pinfo.filteredFileNames))
      call add(result, {
            \ 'group': 'files',
            \ 'word': fileName,
            \ 'abbr': "\t".fileName,
            \ 'kind': 'file',
            \ 'action__path': fileName,
            \ 'source': 'tsproject'
            \ })
    endfor
  endif
  return result
endfunction

function! unite#sources#tsproject#define()
  if tsuquyomi#config#isHigher(160)
    return s:source
  endif
endfunction

