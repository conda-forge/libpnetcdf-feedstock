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

# The shipped configure (Autoconf 2.71) has an AC_HEADER_STDBOOL test that fails
# under C23 (`bool` is a keyword, not a macro), which is the default for GCC 15.
# The false negative leaves HAVE_STDBOOL_H unset, so test/common/testutils.h and
# src/utils/ncmpidump/ncmpidump.h fall back to `enum {false=0, true=1};`, which
# is a hard error when included from C++ (test/CXX). Autoconf 2.72 fixed the
# test; until upstream regenerates configure, pre-seed the cache with the
# correct answer (<stdbool.h> conforms on every platform we build).
export ac_cv_header_stdbool_h=yes

./configure --prefix=${PREFIX} \
            --with-mpi=${PREFIX} \
            --enable-shared=yes \
            --enable-static=no

make -j"${CPU_COUNT}"

# Skip tests if cross-compiling or emulating
if [ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]; then
    # For other plartorms make check/ptest is not always working in CI (not uncommon)
    make check
fi

make install

# Upstream 1.15.0's configure leaks a redundant `-lmpi` into `pnetcdf-config --libs`
# ("extra libraries"), whereas 1.14.1 (incl. when rebuilt against mpich 5) left it
# empty. The shared lib already links libmpi and pnetcdf.pc omits it, but the stray
# `-lmpi` breaks downstreams (e.g. ParallelIO) that treat `--libs` as the full link
# line. Restore the pre-1.15.0 empty value. Anchored to `^LIBS=` so FLIBS/FCLIBS
# (Fortran link flags) are untouched; temp-file rewrite is portable across seds.
_pc="${PREFIX}/bin/pnetcdf-config"
sed 's/^LIBS=.*/LIBS=""/' "${_pc}" > "${_pc}.tmp"
cat "${_pc}.tmp" > "${_pc}"   # preserve exec permissions
rm -f "${_pc}.tmp"
