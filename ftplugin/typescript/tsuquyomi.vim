"============================================================================
" FILE: ftplugin/typescript.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

if !tsuquyomi#config#preconfig()
  finish
endif

setlocal suffixesadd+=.ts

call tsuquyomi#config#initBuffer({ 'pattern': '*.ts,*.tsx' })
