#! /bin/bash

set -e

SYSROOT="${PREFIX}/$(${CC} -dumpmachine)/sysroot"

export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${SYSROOT}/usr/lib64/pkgconfig:${SYSROOT}/usr/share/pkgconfig"

if [ $(uname) = Darwin ] ; then
    # This needs to be kept the same as what was used to build Cairo, which is
    # apparently this:
    export MACOSX_DEPLOYMENT_TARGET=10.9
fi

python setup.py install
