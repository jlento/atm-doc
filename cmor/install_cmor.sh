export LDSHARED_FLAGS="-shared -pthread"
export PREFIX=$(python -c "import sys; print(sys.prefix)")

cd $CW_INSTALLATION_PATH


git clone https://github.com/PCMDI/cmor.git
cd cmor
git submodule init
git submodule update
./configure --prefix=$PREFIX --with-python --with-uuid=$PREFIX --with-json-c=$PREFIX --with-udunits2=$PREFIX --with-netcdf=$PREFIX  --enable-verbose-test
make install
make test
