#!/bin/bash.exe
set -e

cd ..
#make clean
make
cd StandardInput/
../instream.exe -b
