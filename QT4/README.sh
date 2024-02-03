#/bin/bash

# QT4.8 install notes
# puhti.csc.fi, RHEL8
# 2024-02-03, juha.lento@csc.fi

cd $TMPDIR
wget wget https://download.qt.io/archive/qt/4.8/4.8.7/qt-everywhere-opensource-src-4.8.7.tar.gz
tar xf qt-everywhere-opensource-src-4.8.7.tar.gz
cd qt-everywhere-opensource-src-4.8.7
sed 's/^QMAKE_CXX.*/QMAKE_CXX = g++ -std=gnu++98/' mkspecs/common/g++-base.conf
./configure --prefix=/scratch/project_2002239/RT678895 --no-openssl << EOF
o
yes
EOF
make -j 8
make install
