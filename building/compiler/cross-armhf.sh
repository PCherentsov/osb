#!/bin/sh
#
# gcc -mfloat-abi=hard      -march=armv7-a      -mfpu=neon           -mthumb
#    --with-float=hard --with-arch=armv7-a --with-fpu=neon --with-mode=thumb
#

export KERNEL_SRC_ROOT=${HOME}/vcs/git/linux
export EGLIBC_SRC_ROOT=${HOME}/vcs/svn/eglibc-2.17
export GCC_SRC_ROOT=${HOME}/vcs/svn/gcc/branches/gcc-4_8-branch
export BINUTILS_SRC_ROOT=${HOME}/vcs/git/binutils

export NR_JOBS=`cat /proc/cpuinfo | grep '^processor\s*:' | wc -l`
export BUILD_TRIPLET=`/usr/share/misc/config.guess`
export TARGET_TRIPLET=arm-linux-gnueabihf
export LOGGER_TAG=cross-armhf
export SYS_ROOT=${HOME}/cross/${TARGET_TRIPLET}
export PATH=${SYS_ROOT}/usr/bin:${HOME}/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

logger -t ${LOGGER_TAG} -s "Build started"
################ cleanup ################
rm -fr ${SYS_ROOT} ${HOME}/obj/${TARGET_TRIPLET}

################ Linux Kernel header files ################
cd ${KERNEL_SRC_ROOT}
make V=2 ARCH=arm alldefconfig
make V=2 ARCH=arm headers_check
make V=2 ARCH=arm INSTALL_HDR_PATH=${SYS_ROOT}/usr headers_install
logger -t ${LOGGER_TAG} -s "Build linux-libc-dev success"

################ binutils ################
rm -fr ${HOME}/obj/${TARGET_TRIPLET}/binutils
mkdir -p ${HOME}/obj/${TARGET_TRIPLET}/binutils
cd  ${HOME}/obj/${TARGET_TRIPLET}/binutils

${BINUTILS_SRC_ROOT}/configure \
    --prefix=${SYS_ROOT}/usr \
    --with-sysroot=${SYS_ROOT} \
    --target=${TARGET_TRIPLET}

make -j${NR_JOBS} ; make install-strip
if [ $? -ne 0 ]; then
    logger -t ${LOGGER_TAG} -s "Build binutils failed"
    exit 1
fi
logger -t ${LOGGER_TAG} -s "Build binutils success"

################ gcc - mini ################
rm -fr ${HOME}/obj/${TARGET_TRIPLET}/gcc-mini
mkdir -p ${HOME}/obj/${TARGET_TRIPLET}/gcc-mini
cd  ${HOME}/obj/${TARGET_TRIPLET}/gcc-mini

${GCC_SRC_ROOT}/configure \
    --prefix=${SYS_ROOT}/usr \
    --with-sysroot=${SYS_ROOT} \
    --target=${TARGET_TRIPLET} \
    --enable-checking=release \
    --enable-languages=c --with-newlib --without-headers \
    --disable-multilib --disable-shared --disable-threads --disable-libssp --disable-libgomp \
    --disable-libmudflap --disable-libquadmath --disable-libatomic \
    --with-arch=armv7-a --with-float=hard --with-fpu=neon --with-mode=thumb

make -j${NR_JOBS} ; make install-strip
if [ $? -ne 0 ]; then
    logger -t ${LOGGER_TAG} -s "Build gcc (mini) failed"
    exit 1
fi
logger -t ${LOGGER_TAG} -s "Build gcc (mini) success"

################ eglibc ################
rm -fr ${HOME}/obj/${TARGET_TRIPLET}/eglibc
mkdir -p ${HOME}/obj/${TARGET_TRIPLET}/eglibc
cd  ${HOME}/obj/${TARGET_TRIPLET}/eglibc

${EGLIBC_SRC_ROOT}/libc/configure --prefix=/usr --enable-kernel=2.6.32 \
    --host=${TARGET_TRIPLET} --with-headers=${SYS_ROOT}/usr/include

fakeroot make install_root=${SYS_ROOT} install-headers install-bootstrap-headers=yes
make -j${NR_JOBS}
fakeroot make install_root=${SYS_ROOT} install
if [ $? -ne 0 ]; then
    logger -t ${LOGGER_TAG} -s "Build eglibc failed"
    exit 1
fi
logger -t ${LOGGER_TAG} -s "Build eglibc success"

################ gcc - full ################
rm -fr ${HOME}/obj/${TARGET_TRIPLET}/gcc-full
mkdir -p ${HOME}/obj/${TARGET_TRIPLET}/gcc-full
cd  ${HOME}/obj/${TARGET_TRIPLET}/gcc-full

${GCC_SRC_ROOT}/configure \
    --prefix=${SYS_ROOT}/usr \
    --with-sysroot=${SYS_ROOT} \
    --target=${TARGET_TRIPLET} \
    --enable-checking=release \
    --enable-languages=c,c++ \
    --with-float=hard --with-arch=armv7-a --with-fpu=neon --with-mode=thumb

make -j${NR_JOBS} ; make install-strip
if [ $? -ne 0 ]; then
    logger -t ${LOGGER_TAG} -s "Build gcc - full failed"
    exit 1
fi
logger -t ${LOGGER_TAG} -s "Build gcc (full) success"

logger -t ${LOGGER_TAG} -s "Build finished"
