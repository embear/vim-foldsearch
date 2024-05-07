#!/bin/bash

BASEDIR=$(readlink -f "$(dirname $(dirname $0))")

# get latest vader
if [ ! -s ${BASEDIR}/test/vader ]
then
  echo -n "getting vader ... "
  git clone --depth=1 https://github.com/junegunn/vader.vim.git ${BASEDIR}/test/vader >/dev/null 2>&1
  echo "DONE"
fi

# run the tests
echo -n "running tests ... "
OUTPUT=$(vim -Nu <(cat << VIMRC
filetype off
set rtp+=${BASEDIR}
set rtp+=${BASEDIR}/test/vader
filetype plugin indent on
syntax enable
VIMRC
) -c 'Vader! test/test_*.vader' 2>&1)
RC=$?

if [ ${RC} -ne 0 ]
then
  echo "[0;31mFAILED[0m"
  echo
  echo "${OUTPUT}"
else
  echo "DONE"
fi

exit ${RC}
