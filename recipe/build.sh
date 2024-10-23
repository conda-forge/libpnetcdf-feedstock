#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* ./scripts

set -xe

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" && "$mpi" == "openmpi" ]]; then
    export OMPI_MCA_rmaps_base_oversubscribe=yes
    export OMPI_MCA_btl=self,tcp
    export OMPI_MCA_plm=isolated
    export OMPI_MCA_rmaps_base_oversubscribe=yes
    export OMPI_MCA_btl_vader_single_copy_mechanism=none
    mpiexec="mpiexec --allow-run-as-root"
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

make -j"${CPU_COUNT}"

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
    # MPI tests aren't working in CI (not uncommon)
    # make check
    # To avoid issues with 
    # WARNING: You are running 4 MPI processes on a processor that supports up to 2 cores. If you still 
    # wish to run in oversubscribed mode, please set MVP_ENABLE_AFFINITY=0 and re-run the program
    export MVP_ENABLE_AFFINITY=0
    make ptest
fi

make install
