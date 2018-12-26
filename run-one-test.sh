#!/bin/bash

set -xe

if [ "${VERSION}" == "" ]; then
  VERSION=3.2
fi

TSSERVER_PATH="$(pwd)/test/node_modules/typescript-${VERSION}/bin/tsserver"

vim -u test/.vimrc \
  -c 'let g:tsuquyomi_use_local_typescript = 0' \
  -c 'let g:tsuquyomi_use_dev_node_module = 2' \
  -c "let g:tsuquyomi_tsserver_path = \"${TSSERVER_PATH}\""  \
  -c 'call vesting#load()' \
  -c 'call vesting#init()' \
  -c "so $1" -c 'echom string(vesting#get_result())'
