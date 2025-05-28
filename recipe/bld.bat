setlocal EnableDelayedExpansion
@echo on

:: We're using the meson build system as opposed to 'pip install .' because it provides
:: the pkg-config files for `pycairo`. These are used by downstream packages (notably
:: `pygobject`) that also use the meson build system in order to locate `pycairo`.
:: Without them, `pycairo` will not be found and might be built as an in-tree subproject
:: which is obviously undesirable.

:: meson options
:: (set pkg_config_path so deps in host env can be found)
set ^"MESON_OPTIONS=^
  --prefix="%LIBRARY_PREFIX%" ^
  --pkg-config-path="%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig" ^
  --wrap-mode=nofallback ^
  --buildtype=release ^
  --backend=ninja ^
  -D python=%PYTHON% ^
  -D python.install_env=auto ^
 ^"

:: configure build using meson
meson setup builddir !MESON_OPTIONS!
if errorlevel 1 exit 1

:: print results of build configuration
meson configure builddir
if errorlevel 1 exit 1

meson compile -v -C builddir -j %CPU_COUNT%
if errorlevel 1 exit 1

:: Skip tests for Python 3.13 due to known compatibility issues with set_mime_data functionality
:: SystemError: \Objects\abstract.c:430: bad argument to internal function
:: See: https://github.com/pygobject/pycairo/blob/v1.26.1/NEWS#L5-L9
for /f "tokens=*" %%i in ('%PYTHON% -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"') do set PYTHON_VERSION=%%i
if not "%PYTHON_VERSION%"=="3.13" (
  meson test -C builddir --print-errorlogs --timeout-multiplier 10 --num-processes %CPU_COUNT%
  if errorlevel 1 exit 1
) else (
  echo Skipping tests for Python 3.13 due to known compatibility issues with set_mime_data functionality
)

meson install -C builddir
if errorlevel 1 exit 1