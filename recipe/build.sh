#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* ./scripts

set -xe

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" && "$mpi" == "openmpi" ]]; then
    # for cross compiling using openmpi
    export OPAL_PREFIX=${PREFIX}
    COMPILER_PREFIX=${BUILD_PREFIX}/bin
else
    COMPILER_PREFIX=${PREFIX}/bin
fi

export MPICC=${COMPILER_PREFIX}/mpicc
export MPICXX=${COMPILER_PREFIX}/mpicxx
export MPIF77=${COMPILER_PREFIX}/mpifort
export MPIF90=${COMPILER_PREFIX}/mpifort

./configure --prefix=${PREFIX} \
    --with-mpi=${PREFIX} \
    --enable-shared=yes \
    --enable-static=no

make

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
    # MPI tests aren't working in CI (not uncommon)
    make check
    make ptest
fi

make install
