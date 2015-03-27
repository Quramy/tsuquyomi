scriptencoding utf-8

command! -buffer TSQstart : call tsuquyomi#startTss()
command! -buffer TSQstatus : echo tsuquyomi#statusTss()
command! -buffer TSQstop : call tsuquyomi#stopTss()

command! -buffer TSQopen : call tsuquyomi#open()
command! -buffer TSQreload : call tsuquyomi#reload()
command! -buffer TSQdumpCurrent : call tsuquyomi#dumpCurrent()

augroup tsuquyomi_defaults
  autocmd!
  autocmd BufNewFile,BufRead *.ts setlocal omnifunc=tsuquyomi#complete
augroup END

call tsuquyomi#open()
