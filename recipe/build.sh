#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* ./scripts

set -xe

# for cross compiling using openmpi
export OPAL_PREFIX=$PREFIX

# export MPICC=mpicc
# export MPICXX=mpicxx
# export MPIF77=mpifort
# export MPIF90=mpifort

./configure --prefix=${PREFIX} \
    --with-mpi=${PREFIX} \
    --enable-shared=yes \
    --enable-static=no

make

# MPI tests aren't working in CI (not uncommon)
# make check
# make ptest

make install
