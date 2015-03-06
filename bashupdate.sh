#!/bin/bash
cd /src
wget http://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz
#download all patches
for i in $(seq -f "%03g" 1 28); do wget http://ftp.gnu.org/gnu/bash/bash-4.3-patches/bash43-$i; done
tar zxvf bash-4.3.tar.gz
cd bash-4.3
#apply all patches
for i in $(seq -f "%03g" 1 28);do patch -p0 < ../bash43-$i; done
#build and install
./configure --prefix=/ && make && make install
cd ../../
rm -r src
