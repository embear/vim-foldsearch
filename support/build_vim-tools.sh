#!/bin/bash
# build local version of vim-tools

# package settings
PACKAGE=vim-tools
REPO="https://github.com/ycm-core/vim-tools"
HERE=$(readlink -f "$(dirname $0)")
DEST=$(readlink -f "${HERE}/vim-tools")

# die()
die()
{
  echo "[0;31m$@[0m" >&2
  exit 1
}

# get source code
echo "getting sources ..."
git clone "${REPO}" "${DEST}" >/dev/null 2>&1 || die "get sources failed"

# virtualenv
echo "creating virtualenv ..."
virtualenv ${DEST}/virtualenv >/dev/null 2>&1 || die "virtualenv failed"
${DEST}/virtualenv/bin/pip install -r ${DEST}/requirements.txt >/dev/null 2>&1 || die "virtualenv failed"

# executable
mkdir ${DEST}/bin
cat > ${DEST}/bin/html2vimdoc <<EOF
#!/bin/sh
. ${DEST}/virtualenv/bin/activate >/dev/null 2>&1
${DEST}/html2vimdoc.py \$*
EOF
chmod 0755 ${DEST}/bin/html2vimdoc
