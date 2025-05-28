#! /bin/bash

set -ex

# ppc64le cdt need to be rebuilt with files in powerpc64le-conda-linux-gnu instead of powerpc64le-conda_cos7-linux-gnu. In the mean time:
if [ "$(uname -m)" = "ppc64le" ]; then
  cp --force --archive --update --link $BUILD_PREFIX/powerpc64le-conda_cos7-linux-gnu/. $BUILD_PREFIX/powerpc64le-conda-linux-gnu
fi

# We're using the meson build system as opposed to 'pip install .' because it provides
# the pkg-config files for `pycairo`. These are used by downstream packages (notably
# `pygobject`) that also use the meson build system in order to locate `pycairo`.
# Without them, `pycairo` will not be found and might be built as an in-tree subproject
# which is obviously undesirable.

export PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}:${PREFIX}/lib/pkgconfig:$BUILD_PREFIX/$BUILD/sysroot/usr/lib64/pkgconfig:$BUILD_PREFIX/$BUILD/sysroot/usr/share/pkgconfig

# meson options
meson_config_args=(
  --prefix="$PREFIX"
  --wrap-mode=nofallback
  --buildtype=release
  --backend=ninja
  -Dlibdir=lib
  -D python="$PYTHON"
)

# configure build using meson
meson setup builddir ${MESON_ARGS} "${meson_config_args[@]}"

meson compile -v -C builddir -j ${CPU_COUNT}

# Skip tests for Python 3.13 due to known compatibility issues with set_mime_data functionality
# See: https://github.com/pygobject/pycairo/issues/366
PYTHON_VERSION=$($PYTHON -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
if [[ "$PYTHON_VERSION" != "3.13" ]]; then
  meson test -C builddir --print-errorlogs --timeout-multiplier 10 --num-processes ${CPU_COUNT}
else
  # SystemError: /var/folders/.../Objects/abstract.c:430: bad argument to internal function,
  # See: https://github.com/pygobject/pycairo/blob/v1.26.1/NEWS#L5-L9
  echo "Skipping tests for Python 3.13 due to known compatibility issues with set_mime_data functionality"
fi

meson install -C builddir