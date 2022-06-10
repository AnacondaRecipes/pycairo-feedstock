#! /bin/bash

set -e

# We're using the meson build system as opposed to 'pip install .' because it provides
# the pkg-config files for `pycairo`. These are used by downstream packages (notably
# `pygobject`) that also use the meson build system in order to locate `pycairo`.
# Without them, `pycairo` will not be found and might be built as an in-tree subproject
# which is obviously undesirable.

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
meson test -C builddir --print-errorlogs --timeout-multiplier 10 --num-processes ${CPU_COUNT}
meson install -C builddir