"============================================================================
" FILE: ftplugin/javascript.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

if !g:tsuquyomi_javascript_support
  finish
endif

if !tsuquyomi#config#preconfig()
  finish
endif

call tsuquyomi#config#initBuffer({ 'pattern': '*.js,*.jsx' })
