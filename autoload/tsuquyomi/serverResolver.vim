"============================================================================
" FILE: autoload/tsuquyomi/serverResolver.vim
" AUTHOR: Quramy <yosuke.kurami@gmail.com>
"============================================================================
"
scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('tsuquyomi')
let s:Filepath = s:V.import('System.Filepath')
let s:JSON = s:V.import('Web.JSON')

let s:tss_cmd = ''

function! s:readPackageJson()
  let prj_dir = tsuquyomi#config#project_dir()
  let package_json_path = s:Filepath.join(prj_dir, 'package.json')
  if !filereadable(package_json_path) 
    return
  endif
  return s:JSON.decode(join(readfile(package_json_path)))
endfunction

function! s:is_jspm(pkg_json)
  return has_key(a:pkg_json, 'jspm')
endfunction

function! s:jspm_base(pkg_json)
  if !has_key(a:pkg_json, 'jspm')
    return ''
  endif
  if !has_key(a:pkg_json.jspm, 'directories')
    return ''
  endif
  if !has_key(a:pkg_json.jspm.directories, 'baseURL')
    return ''
  endif
  return a:pkg_json.jspm.directories.baseURL
endfunction

function! s:get_jspm_executable_path()
  let prj_dir = tsuquyomi#config#project_dir()
  let package_json_path = s:Filepath.join(prj_dir, 'package.json')
  if !filereadable(package_json_path) 
    return
  endif
  let pkg_json = s:readPackageJson()
  if !s:is_jspm(pkg_json)
    return
  endif
  let jspm_base = s:jspm_base(pkg_json)
  let jspm_dir = s:Filepath.join(prj_dir, jspm_base)

  " TODO read package path mapping by System.js setting.
  let package_list = globpath(s:Filepath.join(jspm_dir, 'jspm_packages', 'npm'), 'typescript@*', 0, 1)
  let hit_pkg = 0
  for package_name in package_list
    if isdirectory(package_name)
      return s:Filepath.join(package_name, 'bin', 'tsserver')
    endif
  endfor
endfunction

function! tsuquyomi#serverResolver#get_tsscmd()
  if s:tss_cmd !=# ''
    return s:tss_cmd
  endif
  if g:tsuquyomi_use_local_typescript != 0
    let l:prj_dir = tsuquyomi#config#project_dir()
    if l:prj_dir !=# ''
      let l:searched_tsserver_path = s:Filepath.join(l:prj_dir, 'node_modules/typescript/bin/tsserver')
      if filereadable(l:searched_tsserver_path)
        return g:tsuquyomi_nodejs_path.' "'.l:searched_tsserver_path.'"'
      endif
      let l:searched_tsserver_path = s:get_jspm_executable_path()
      if filereadable(l:searched_tsserver_path)
        return g:tsuquyomi_nodejs_path.' "'.l:searched_tsserver_path.'"'
      endif
    endif
  endif
  if g:tsuquyomi_use_dev_node_module == 0
    let l:cmd = 'tsserver'
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
    if filereadable(l:path) != 1
      echom '[Tsuquyomi] tsserver.js does not exist. Try "npm install"., '.l:path
      return ''
    endif
    let l:cmd = g:tsuquyomi_nodejs_path.' "'.l:path.'"'
  endif
  return l:cmd
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
