#!/bin/bash
rm -rf cmake-build/
mkdir cmake-build
cd cmake-build
cmake -DCMAKE_BUILD_TYPE=Release ..
make
