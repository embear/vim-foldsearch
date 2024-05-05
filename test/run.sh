#!/bin/bash

BASEDIR=$(readlink -f "$(dirname $(dirname $0))")

# get latest vader
if [ ! -s ${BASEDIR}/test/vader ]
then
  echo "getting sources ..."
  git clone --depth=1 https://github.com/junegunn/vader.vim.git ${BASEDIR}/test/vader >/dev/null 2>&1
fi

# run the tests
echo "running tests ..."
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
  echo "${OUTPUT}"
  echo
  echo "FAILED"
  echo
else
  echo "SUCCESS"
fi

exit ${RC}
