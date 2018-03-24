"============================================================================
" FILE: ftplugin/typescript.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================

scriptencoding utf-8

if !tsuquyomi#config#preconfig()
  finish
endif

call tsuquyomi#config#initBuffer({ 'pattern': '*.ts,*.tsx' })
