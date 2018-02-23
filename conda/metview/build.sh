mkdir build
cd build

cmake .. \
      -DCMAKE_PREFIX_PATH="$PREFIX" \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" \
      -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath=${PREFIX}/lib -leccodes_f90"

make
make install
