#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* ./scripts

set -xe

export MPICC=${PREFIX}/mpicc
export MPICXX=${PREFIX}/mpicxx
export MPIF77=${PREFIX}/mpifort
export MPIF90=${PREFIX}/mpifort

./configure --prefix=${PREFIX} \
            --with-mpi=${PREFIX} \
            --enable-shared=yes \
            --enable-static=no

make -j"${CPU_COUNT}"

if [[ "$target_platform" == "linux-64" ]]; then
    # For other plartorms make check/ptest is not always working in CI (not uncommon)
    make check
fi

make install
