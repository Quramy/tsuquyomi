#/bin/sh

VIMRC_FILE="vest/.vimrc"
DRIVER_FILE="vest/_runner"
RESULT_FILE="vest/test_result.log"
VIM_BUILD=1
VIM_INSTALL_DIR=`pwd`/local

if [ "${VIM_BUILD}" -eq 1 ]; then
  echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Use local Vim."
  if [ ! -d "./local" ]; then
    echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Installing Vim"
    if [ ! -d "./vim" ]; then
      echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Clonning Vim source from Github"
      git clone https://github.com/vim-jp/vim.git
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
  git clone https://github.com/Shougo/neobundle.vim
fi

if [ -f "${RESULT_FILE}" ]; then
  rm ${RESULT_FILE}
fi

echo "`date "+[%Y-%m-%dT%H:%M:%S]"` Run vesting."
${VIM_CMD} -u ${VIMRC_FILE} -s ${DRIVER_FILE}
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

