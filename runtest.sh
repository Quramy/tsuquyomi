#!/bin/bash

VIMRC_FILE="test/.vimrc"
DRIVER_FILE="test/_runner"
RESULT_FILE="test/test_result.log"
VIM_BUILD=1
VIM_INSTALL_DIR=`pwd`/local
if [ "${VERSION}" == "" ]; then
  VERSION=3.2
fi
TSSERVER_PATH="$(pwd)/test/node_modules/typescript-${VERSION}/bin/tsserver"

echo "Run test with ${TSSERVER_PATH}"

if [ "${VIM_BUILD}" -eq 1 ]; then
  echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Use local Vim."
  if [ ! -d "./local" ]; then
    echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Installing Vim"
    if [ ! -d "./vim" ]; then
      echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Clonning Vim source from Github"
      git clone --depth 1 https://github.com/vim/vim.git
    fi
    cd vim
    ./configure --prefix=${VIM_INSTALL_DIR}
    if [ ! $? -eq 0 ]; then
      exit $?
    fi
    make
    if [ ! $? -eq 0 ]; then
      exit $?
    fi
    make install
    if [ ! $? -eq 0 ]; then
      exit $?
    fi
    echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Vim was created successfully."
    cd ..
  fi
  VIM_CMD="${VIM_INSTALL_DIR}/bin/vim"
else
  echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Use system Vim."
  VIM_CMD="vim"
fi

${VIM_CMD} --version

if [ ! -d "./neobundle.vim" ]; then
  echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Installing neobundle"
  git clone --depth 1 https://github.com/Shougo/neobundle.vim
fi

if [ "${HIDE_VIM}" == "" ]; then
  ${VIM_CMD} -u ${VIMRC_FILE} -c NeoBundleInstall -c q
else
  ${VIM_CMD} -u ${VIMRC_FILE} -c NeoBundleInstall -c q > /dev/null
fi

if [ -f "${RESULT_FILE}" ]; then
  rm ${RESULT_FILE}
fi

echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Run vesting."
# In CI, displaying Vim UI is meaningless and it makes CI logs dirty.
# So hide Vim UI.
if [ "${HIDE_VIM}" == "" ]; then
  ${VIM_CMD} \
    -c 'let g:tsuquyomi_use_local_typescript = 0' \
    -c 'let g:tsuquyomi_use_dev_node_module = 2' \
    -c "let g:tsuquyomi_tsserver_path = \"${TSSERVER_PATH}\""  \
    -u ${VIMRC_FILE} \
    -s ${DRIVER_FILE}
else
  ${VIM_CMD} \
    -c 'let g:tsuquyomi_use_local_typescript = 0' \
    -c 'let g:tsuquyomi_use_dev_node_module = 2' \
    -c "let g:tsuquyomi_tsserver_path = \"${TSSERVER_PATH}\""  \
    -u ${VIMRC_FILE} \
    -s ${DRIVER_FILE} > /dev/null
fi
if [ $? -ne 0 ]; then
  echo "Vim exited with non-zero status."
  exit 1
fi
echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Done."
echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Result: (${RESULT_FILE})"
cat ${RESULT_FILE}

grep -E "\[Fail\]" ${RESULT_FILE} > /dev/null

if [ $? -eq 0 ]; then
  echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Test was failed."
  exit 1
fi

grep -E "\[Error\]" ${RESULT_FILE} > /dev/null

if [ $? -eq 0 ]; then
  echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Test was failed."
  exit 1
fi

echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Test was succeeded."
exit 0

