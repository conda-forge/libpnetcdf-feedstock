#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* ./scripts

set -xe

if [[ ! -z "$mpi" && "$mpi" != "nompi" ]]; then
  export OMPI_MCA_rmaps_base_oversubscribe=yes
  export OMPI_MCA_btl=self,tcp
  export OMPI_MCA_plm=isolated
  export OMPI_MCA_rmaps_base_oversubscribe=yes
  export OMPI_MCA_btl_vader_single_copy_mechanism=none
  mpiexec="mpiexec --allow-run-as-root"
  # for cross compiling using openmpi
  export OPAL_PREFIX=$PREFIX
fi

export MPICC=mpicc
export MPICXX=mpicxx
export MPIF77=mpifort
export MPIF90=mpifort

./configure --prefix=${PREFIX} \
    --with-mpi=${PREFIX} \
    --enable-shared=yes \
    --enable-static=no

make

# MPI tests aren't working in CI (not uncommon)
# make check
# make ptest

make install
