"============================================================================
" FILE: autoload/tsuquyomi/config.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================
"
scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('tsuquyomi')
let s:P = s:V.import('ProcessManager')
let s:Process = s:V.import('Process')
let s:Prelude = s:V.import('Prelude')
let s:Filepath = s:V.import('System.Filepath')
let s:script_dir = expand('<sfile>:p:h')

let s:tss_cmd = ''
let s:tss_version = {'is_valid': 0, 'out': '???'}

let s:is_vim8 = has('patch-8.0.1')

function! tsuquyomi#config#preconfig()

  if !exists('g:tsuquyomi_is_available')
    if !s:is_vim8 && !s:P.is_available()
      " 1. vimproc or vim8 installation check
      let g:tsuquyomi_is_available = 0
      call s:deleteCommand()
      echom '[Tsuquyomi] Shougo/vimproc.vim or vim8 is not installed. Please install it.'
      return 0
    else
      " 2. tsserver installation check
      let s:tss_cmd = tsuquyomi#config#tsscmd()
      if s:tss_cmd == ''
        let g:tsuquyomi_is_available = 0
        call s:deleteCommand()
        return 0
      endif

      " 3. TypeScript version check
      call tsuquyomi#config#getVersion()
      if !s:tss_version.is_valid
        let g:tsuquyomi_is_available = 0
        call s:deleteCommand()
        echom '[Tsuquyomi] Your TypeScript version is invalid. '.s:tss_version.out
        return 0
      endif
      if !tsuquyomi#config#isHigher(150)
        let g:tsuquyomi_is_available = 0
        call s:deleteCommand()
        echom '[Tsuquyomi] tsuquyomi requires typescript@~1.5.0'
        return 0
      endif
      let g:tsuquyomi_is_available = 1
    endif
  endif

  return g:tsuquyomi_is_available
endfunction

function! s:deleteCommand()
  delc TsuquyomiStartServer
  delc TsuStartServer
  delc TsuquyomiStopServer
  delc TsuStopServer
  delc TsuquyomiStatusServer
  delc TsuStatusServer
  delc TsuquyomiReloadProject
  delc TsuReloadProject
endfunction

function! tsuquyomi#config#tssargs()
  let args = []
  call add(args, '--locale '.g:tsuquyomi_locale)
  return join(args, ' ')
endfunction

" Search from cwd upward looking for first directory with package.json
function! tsuquyomi#config#_path2project_directory_ts()
  let parent = getcwd()

  while 1
    let path = parent . '/package.json'
    if filereadable(path)
      return parent
    endif
    let next = fnamemodify(parent, ':h')
    if next == parent
      return ''
    endif
    let parent = next
  endwhile
endfunction

function! tsuquyomi#config#tsscmd()
  if s:tss_cmd !=# ''
    return s:tss_cmd
  endif
  if g:tsuquyomi_use_local_typescript != 0
    let l:prj_dir = tsuquyomi#config#_path2project_directory_ts()

    if l:prj_dir == ''
      " Fallback to generic project root search
      let l:prj_dir = s:Prelude.path2project_directory(getcwd(), 1)
    endif

    if l:prj_dir !=# ''
      let l:searched_tsserver_path = s:Filepath.join(l:prj_dir, 'node_modules/typescript/bin/tsserver')
      if filereadable(l:searched_tsserver_path)
        return g:tsuquyomi_nodejs_path.' "'.l:searched_tsserver_path.'"'
      endif
    endif
  endif
  if g:tsuquyomi_use_dev_node_module == 0
    let l:cmd = 'tsserver'
    if has('win32') || has('win64')
      let l:cmd .= '.cmd'
    endif
    if !executable(l:cmd)
      echom '[Tsuquyomi] tsserver is not installed. Try "npm -g install typescript".'
      return ''
    endif
  else
    if g:tsuquyomi_use_dev_node_module == 1
      let l:path = s:Filepath.join(s:script_dir, '../../node_modules/typescript/bin/tsserver')
    elseif g:tsuquyomi_use_dev_node_module == 2
      let l:path = g:tsuquyomi_tsserver_path
    else
      echom '[Tsuquyomi] Invalid option value "g:tsuquyomi_use_dev_node_module".'
      return ''
    endif
    if (has('win32') || has('win64')) && l:path !~ '\.cmd$'
      let l:path .= '.cmd'
    endif
    if filereadable(l:path) != 1
      echom '[Tsuquyomi] tsserver.js does not exist. Try "npm install"., '.l:path
      return ''
    endif
    if !s:is_vim8
      let l:cmd = g:tsuquyomi_nodejs_path.' "'.l:path.'"'
    else
      let l:cmd = g:tsuquyomi_nodejs_path.' '.l:path
    endif
  endif
  return l:cmd
endfunction

function! tsuquyomi#config#getVersion()
  if s:tss_version.is_valid
    return s:tss_version
  endif
  let l:cmd = substitute(tsuquyomi#config#tsscmd(), 'tsserver', 'tsc', '')
  let l:cmd = substitute(l:cmd, "\\", "/", "g")
  let out = s:Process.system(l:cmd.' --version')
  let pattern = '\vVersion\s+(\d+)\.(\d+)\.(\d+)-?([^\.\n\s]*)'
  let matched = matchlist(out, pattern)
  if !len(matched)
    let s:tss_version = {'is_valid': 0, 'out': out}
    return s:tss_version
  endif
  let [major, minor, patch] = [str2nr(matched[1]), str2nr(matched[2]), str2nr(matched[3])]
  let s:tss_version = {
        \ 'is_valid': 1,
        \ 'major': major, 'minor': minor, 'patch': patch,
        \ 'channel': matched[4],
        \ }
  return s:tss_version
endfunction

function! tsuquyomi#config#isHigher(target)
  if !s:tss_version.is_valid
    return 0
  endif
  let numeric_version = s:tss_version.major * 100 + s:tss_version.minor * 10 + s:tss_version.patch
  return numeric_version >= a:target
endfunction

function! tsuquyomi#config#createBufLocalCommand()
  command! -buffer -nargs=* -complete=buffer TsuquyomiOpen    :call tsuquyomi#open(<f-args>)
  command! -buffer -nargs=* -complete=buffer TsuOpen          :call tsuquyomi#open(<f-args>)
  command! -buffer -nargs=* -complete=buffer TsuquyomiClose   :call tsuquyomi#close(<f-args>)
  command! -buffer -nargs=* -complete=buffer TsuClose         :call tsuquyomi#close(<f-args>)
  command! -buffer -nargs=* -complete=buffer TsuquyomiReload  :call tsuquyomi#reload(<f-args>)
  command! -buffer -nargs=* -complete=buffer TsuReload        :call tsuquyomi#reload(<f-args>)
  command! -buffer -nargs=* -complete=buffer TsuquyomiDump    :call tsuquyomi#dump(<f-args>)
  command! -buffer -nargs=* -complete=buffer TsuDump          :call tsuquyomi#dump(<f-args>)
  command! -buffer -nargs=1 TsuquyomiSearch                   :call tsuquyomi#navtoByLoclistContain(<f-args>)
  command! -buffer -nargs=1 TsuSearch                         :call tsuquyomi#navtoByLoclistContain(<f-args>)

  command! -buffer TsuquyomiDefinition      :call tsuquyomi#definition()
  command! -buffer TsuDefinition            :call tsuquyomi#definition()
  command! -buffer TsuquyomiSplitDefinition :call tsuquyomi#splitDefinition()
  command! -buffer TsuSplitDefinition       :call tsuquyomi#splitDefinition()
  command! -buffer TsuquyomiGoBack          :call tsuquyomi#goBack()
  command! -buffer TsuGoBack                :call tsuquyomi#goBack()
  command! -buffer TsuquyomiImplementation  :call tsuquyomi#implementation()
  command! -buffer TsuImplementation        :call tsuquyomi#implementation()
  command! -buffer TsuquyomiReferences      :call tsuquyomi#references()
  command! -buffer TsuReferences            :call tsuquyomi#references()
  command! -buffer TsuquyomiTypeDefinition  :call tsuquyomi#typeDefinition()
  command! -buffer TsuTypeDefinition        :call tsuquyomi#typeDefinition()
  command! -buffer TsuquyomiGeterr          :call tsuquyomi#geterr()
  command! -buffer TsuGeterr                :call tsuquyomi#geterr()
  command! -buffer TsuquyomiGeterrProject   :call tsuquyomi#geterrProject()
  command! -buffer TsuGeterrProject         :call tsuquyomi#geterrProject()
  command! -buffer TsuquyomiRenameSymbol    :call tsuquyomi#renameSymbol()
  command! -buffer TsuRenameSymbol          :call tsuquyomi#renameSymbol()
  command! -buffer TsuquyomiRenameSymbolC   :call tsuquyomi#renameSymbolWithComments()
  command! -buffer TsuRenameSymbolC         :call tsuquyomi#renameSymbolWithComments()
  command! -buffer TsuquyomiQuickFix        :call tsuquyomi#quickFix()
  command! -buffer TsuQuickFix              :call tsuquyomi#quickFix()
  command! -buffer TsuquyomiSignatureHelp   :call tsuquyomi#signatureHelp()
  command! -buffer TsuSignatureHelp         :call tsuquyomi#signatureHelp()
  command! -buffer TsuAsyncGeterr           :call tsuquyomi#asyncGeterr()
  command! -buffer TsuquyomiAsyncGeterr     :call tsuquyomi#asyncGeterr()

  " TODO These commands don't work correctly.
  command! -buffer TsuquyomiRenameSymbolS   :call tsuquyomi#renameSymbolWithStrings()
  command! -buffer TsuRenameSymbolS         :call tsuquyomi#renameSymbolWithStrings()
  command! -buffer TsuquyomiRenameSymbolCS  :call tsuquyomi#renameSymbolWithCommentsStrings()
  command! -buffer TsuRenameSymbolCS        :call tsuquyomi#renameSymbolWithCommentsStrings()

  command! -buffer TsuquyomiImport          :call tsuquyomi#es6import#complete()
  command! -buffer TsuImport                :call tsuquyomi#es6import#complete()
endfunction

function! tsuquyomi#config#createBufLocalMap()
  noremap <silent> <buffer> <Plug>(TsuquyomiDefinition)      :TsuquyomiDefinition <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiSplitDefinition) :TsuquyomiSplitDefinition <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiTypeDefinition)  :TsuquyomiTypeDefinition <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiGoBack)          :TsuquyomiGoBack <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiImplementation)  :TsuquyomiImplementation <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiReferences)      :TsuquyomiReferences <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiRenameSymbol)    :TsuquyomiRenameSymbol <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiRenameSymbolC)   :TsuquyomiRenameSymbolC <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiQuickFix)        :TsuquyomiQuickFix <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiSignatureHelp)   :TsuquyomiSignatureHelp <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiImport)          :TsuquyomiImport <CR>

  " TODO These commands don't work correctly.
  noremap <silent> <buffer> <Plug>(TsuquyomiRenameSymbolS)   :TsuquyomiRenameSymbolS <CR>
  noremap <silent> <buffer> <Plug>(TsuquyomiRenameSymbolCS)  :TsuquyomiRenameSymbolCS <CR>
endfunction

function! tsuquyomi#config#applyBufLocalDefaultMap()
  if(!exists('g:tsuquyomi_disable_default_mappings'))
    if !hasmapto('<Plug>(TsuquyomiDefinition)')
        map <buffer> <C-]> <Plug>(TsuquyomiDefinition)
    endif
    if !hasmapto('<Plug>(TsuquyomiSplitDefinition)')
        map <buffer> <C-W>] <Plug>(TsuquyomiSplitDefinition)
        map <buffer> <C-W><C-]> <Plug>(TsuquyomiSplitDefinition)
    endif
    if !hasmapto('<Plug>(TsuquyomiGoBack)')
        map <buffer> <C-t> <Plug>(TsuquyomiGoBack)
    endif
    if !hasmapto('<Plug>(TsuquyomiReferences)')
        map <buffer> <C-^> <Plug>(TsuquyomiReferences)
    endif
  endif
endfunction

let s:autocmd_patterns = []
function! tsuquyomi#config#applyBufLocalAutocmd(pattern)
  if index(s:autocmd_patterns, a:pattern) == -1
    call add(s:autocmd_patterns, a:pattern)
  endif
  let all_patterns = join(s:autocmd_patterns, ",")
  if !g:tsuquyomi_disable_quickfix
    augroup tsuquyomi_geterr
      autocmd!
      execute 'autocmd BufWritePost '.all_patterns.' silent! call tsuquyomi#reloadAndGeterr()'
    augroup END
  endif

  augroup tsuquyomi_defaults
    autocmd!
    autocmd BufWinEnter * silent! call tsuquyomi#setPreviewOption()
    execute 'autocmd TextChanged,TextChangedI '.all_patterns.' silent! call tsuquyomi#letDirty()'
  augroup END
endfunction

function! tsuquyomi#config#applyBufLocalFunctions()
  setlocal omnifunc=tsuquyomi#complete

  if exists('+bexpr')
    setlocal bexpr=tsuquyomi#balloonexpr()
  endif
endfunction

function! tsuquyomi#config#registerInitialCallback()
  call tsuquyomi#tsClient#registerCallback('tsuquyomi#tsClient#readDiagnostics', 'diagnostics')
endfunction

let s:async_initialized = 0
function! tsuquyomi#config#initBuffer(opt)
  if !has_key(a:opt, 'pattern')
    echom '[Tsuquyomi] missing options. "pattern"'
    return 0
  endif
  let pattern = a:opt.pattern
  call tsuquyomi#config#createBufLocalCommand()
  call tsuquyomi#config#createBufLocalMap()
  call tsuquyomi#config#applyBufLocalDefaultMap()
  call tsuquyomi#config#applyBufLocalAutocmd(pattern)
  call tsuquyomi#config#applyBufLocalFunctions()
  if g:tsuquyomi_auto_open
    silent! call tsuquyomi#open()
    silent! call tsuquyomi#sendConfigure()
  endif
  if s:is_vim8 && g:tsuquyomi_use_vimproc == 0 && s:async_initialized == 0
    call tsuquyomi#config#registerInitialCallback()
    let s:async_initialized = 1
  endif
  return 1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
