mkdir build
cd build
cmake .. -G "$CMAKE_GENERATOR" -DCMAKE_PREFIX_PATH="$PREFIX" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_Fortran_FLAGS="-ffree-line-length-none" -DCMAKE_EXE_LINKER_FLAGS="-leccodes_f90 -leccodes"

make
make install
