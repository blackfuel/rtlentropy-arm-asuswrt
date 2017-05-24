#!/bin/bash
#############################################################################
# rtl-entropy for AsusWRT
#
# This script downloads and compiles all packages needed for adding 
# hardware RNG capability to Asus ARM routers.
#
# Before running this script, you must first compile your router firmware so
# that it generates the AsusWRT libraries.  Do not "make clean" as this will
# remove the libraries needed by this script.
#############################################################################
PATH_CMD="$(readlink -f $0)"

set -e
set -x

#REBUILD_ALL=0
PACKAGE_ROOT="$HOME/asuswrt-merlin-addon/asuswrt"
SRC="$PACKAGE_ROOT/src"
ASUSWRT_MERLIN="$HOME/asuswrt-merlin"
TOP="$ASUSWRT_MERLIN/release/src/router"
FIRMWARE="$TOP/arm-uclibc/target"
OPENSSL_SRC="$TOP/openssl"
OPENSSL="$OPENSSL_SRC"
LIBUSB_SRC="$TOP/libusb10"
LIBUSB="$LIBUSB_SRC/libusb/.libs"
BRCMARM_TOOLCHAIN="$ASUSWRT_MERLIN/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3"
SYSROOT="$BRCMARM_TOOLCHAIN/arm-brcm-linux-uclibcgnueabi/sysroot"

echo $PATH | grep -qF /opt/brcm-arm || export PATH=$PATH:/opt/brcm-arm/bin:/opt/brcm-arm/arm-brcm-linux-uclibcgnueabi/bin:/opt/brcm/hndtools-mipsel-linux/bin:/opt/brcm/hndtools-mipsel-uclibc/bin

[ ! -d /opt ] && sudo mkdir -p /opt
[ ! -h /opt/brcm ] && sudo ln -sf $HOME/asuswrt-merlin/tools/brcm /opt/brcm
[ ! -h /opt/brcm-arm ] && sudo ln -sf $HOME/asuswrt-merlin/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3 /opt/brcm-arm
[ ! -d /projects/hnd/tools/linux ] && sudo mkdir -p /projects/hnd/tools/linux
[ ! -h /projects/hnd/tools/linux/hndtools-arm-linux-2.6.36-uclibc-4.5.3 ] && sudo ln -sf /opt/brcm-arm /projects/hnd/tools/linux/hndtools-arm-linux-2.6.36-uclibc-4.5.3

#sudo apt-get install  xutils-dev libltdl-dev automake1.11
#MAKE="make -j`nproc`"
MAKE="make -j1"

if [ ! -d "$FIRMWARE" ]; then
  echo "I need some firmware files. Please build AsusWRT before continuing."
  exit 1
fi

pushd .
mkdir -p $PACKAGE_ROOT/usr/lib
cd $PACKAGE_ROOT/usr/lib
ln -sf $OPENSSL/libssl.so.1.0.0 libssl.so.1.0.0
ln -sf libssl.so.1.0.0 libssl.so
if [ -f "$OPENSSL/libssl.a" ]; then
  ln -sf $OPENSSL/libssl.a libssl.a
else
  rm -f libssl.a
fi
popd

pushd .
mkdir -p $PACKAGE_ROOT/usr/lib
cd $PACKAGE_ROOT/usr/lib
ln -sf $OPENSSL/libcrypto.so.1.0.0 libcrypto.so.1.0.0
ln -sf libcrypto.so.1.0.0 libcrypto.so
if [ -f "$OPENSSL/libcrypto.a" ]; then
  ln -sf $OPENSSL/libcrypto.a libcrypto.a
else
  rm -f libcrypto.a
fi
popd

pushd .
mkdir -p $PACKAGE_ROOT/usr/include
cd $PACKAGE_ROOT/usr/include
ln -sf $OPENSSL/include/openssl openssl
popd

pushd .
mkdir -p $PACKAGE_ROOT/usr/lib
cd $PACKAGE_ROOT/usr/lib
ln -sf $LIBUSB/libusb-1.0.so.0.0.0 libusb-1.0.so.0.0.0
ln -sf libusb-1.0.so.0.0.0 libusb-1.0.so
ln -sf libusb-1.0.so.0.0.0 libusb-1.0.so.0
if [ -f "$LIBUSB/libusb-1.0.a" ]; then
  ln -sf $LIBUSB/libusb-1.0.a libusb-1.0.a
else
  rm -f libusb-1.0.a
fi
if [ -f "$LIBUSB/libusb-1.0.la" ]; then
  ln -sf $LIBUSB/libusb-1.0.la libusb-1.0.la
else
  rm -f libusb-1.0.la
fi
popd

LIBS="-L$PACKAGE_ROOT/lib/libcap.a $PACKAGE_ROOT/lib/libcap.a -L$PACKAGE_ROOT/lib/librtlsdr.a $PACKAGE_ROOT/lib/librtlsdr.a -L$PACKAGE_ROOT/usr/lib/libusb-1.0.a $PACKAGE_ROOT/usr/lib/libusb-1.0.a  -L$PACKAGE_ROOT/usr/lib/libssl.a $PACKAGE_ROOT/usr/lib/libssl.a  -L$PACKAGE_ROOT/usr/lib/libcrypto.a $PACKAGE_ROOT/usr/lib/libcrypto.a $SYSROOT/usr/lib/libdl.a $SYSROOT/usr/lib/libdl.a -L$SYSROOT/usr/lib/libpthread.a $SYSROOT/usr/lib/libpthread.a -L$SYSROOT/usr/lib/libm.a $SYSROOT/usr/lib/libm.a -L$SYSROOT/usr/lib/librt.a $SYSROOT/usr/lib/librt.a -L$SYSROOT/usr/lib/libc.a $SYSROOT/usr/lib/libc.a -L$PACKAGE_ROOT/usr/lib -L$PACKAGE_ROOT/lib"


########## ##################################################################
# LIBCAP # ##################################################################
########## ##################################################################

DL="libcap-2.25.tar.gz"
URL="http://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/$DL"
mkdir -p $SRC/libcap && cd $SRC/libcap
FOLDER="${DL%.tar.gz*}"
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

if [ ! -f "libcap/include/linux/xattr.h" ]; then
  mkdir -p libcap/include/linux
  cp -p "${PATH_CMD%/*}/asuswrt-kernel-headers/linux/xattr.h" libcap/include/linux
fi

cd libcap
$MAKE _makenames
cd ..

$MAKE install \
DESTDIR="$PACKAGE_ROOT" \
prefix="" \
CC="arm-brcm-linux-uclibcgnueabi-gcc" \
AR="arm-brcm-linux-uclibcgnueabi-ar" \
RANLIB="arm-brcm-linux-uclibcgnueabi-ranlib" \
CFLAGS="-ffunction-sections -fdata-sections -O3 -pipe -march=armv7-a -mtune=cortex-a9 -fno-caller-saves -mfloat-abi=soft -Wall -fPIC -std=gnu99 -I$(pwd)/libcap/include" \
LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections $LIBS" \
BUILD_CC="gcc" \
BUILD_CFLAGS="-I$(pwd)/libcap/include" \
INDENT="| true" \
PAM_CAP="no" \
RAISE_SETFCAP="no" \
DYNAMIC="yes" \
lib="lib"

touch __package_installed
fi

########### #################################################################
# RTL-SDR # #################################################################
########### #################################################################

URL="git://git.osmocom.org/rtl-sdr.git"
FOLDER="${URL##*/}"
FOLDER="${FOLDER%.*}"
DL="${FOLDER}.tar.gz"
mkdir -p $SRC/rtl-sdr && cd $SRC/rtl-sdr
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && rm -rf "$FOLDER" && git clone $URL && tar czvf $DL $FOLDER
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

[ ! -f "configure" ] && autoreconf -i

PKG_CONFIG_PATH="$PACKAGE_ROOT/lib/pkgconfig" \
OPTS="-ffunction-sections -fdata-sections -O3 -pipe -march=armv7-a -mtune=cortex-a9 -fno-caller-saves -mfloat-abi=soft -Wall -fPIC -std=gnu99 -I$PACKAGE_ROOT/include" \
CFLAGS="$OPTS" CPPFLAGS="$OPTS" CXXFLAGS="$OPTS" \
LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections $LIBS" \
./configure \
--host=arm-brcm-linux-uclibcgnueabi \
'--build=' \
--prefix="$PACKAGE_ROOT" \
--enable-static \
--disable-shared \
--disable-silent-rules \
--enable-driver-detach

$MAKE
make install
touch __package_installed
fi

############### #############################################################
# RTL-ENTROPY # #############################################################
############### #############################################################

URL="https://github.com/pwarren/rtl-entropy.git"
FOLDER="${URL##*/}"
FOLDER="${FOLDER%.*}"
DL="${FOLDER}.tar.gz"
mkdir -p $SRC/rtl-entropy && cd $SRC/rtl-entropy
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && rm -rf "$FOLDER" && git clone $URL && tar czvf $DL $FOLDER
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

rm -rf build
mkdir -p build
cd build

ARM_COMPILER_FLAGS="-ffunction-sections -fdata-sections -O3 -pipe -march=armv7-a -mtune=cortex-a9 -fno-caller-saves -mfloat-abi=soft -Wall -fPIC -std=gnu99"
ARM_LINKER_FLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections $LIBS"
ARM_LINK_EXECUTABLE="arm-brcm-linux-uclibcgnueabi-gcc  -ffunction-sections -fdata-sections -O3 -pipe -march=armv7-a -mtune=cortex-a9 -fno-caller-saves -mfloat-abi=soft -Wall -fPIC -std=gnu99 -O3 -DNDEBUG  -ffunction-sections -fdata-sections -Wl,--gc-sections CMakeFiles/rtlentropylib.dir/fips.c.o CMakeFiles/rtlentropylib.dir/log.c.o CMakeFiles/rtlentropylib.dir/util.c.o CMakeFiles/rtl_entropy.dir/rtl_entropy.c.o  -o rtl_entropy -rdynamic $LIBS"
cmake \
-DCMAKE_SYSTEM_NAME="Linux" \
-DCMAKE_SYSTEM_VERSION="2.6.36.4brcmarm" \
-DCMAKE_SYSTEM_VERSION="arm" \
-DCMAKE_FIND_ROOT_PATH="$PACKAGE_ROOT" \
-DCMAKE_INSTALL_PREFIX="$PACKAGE_ROOT" \
-DCMAKE_PREFIX_PATH="$PACKAGE_ROOT" \
-DCMAKE_C_COMPILER="/opt/brcm-arm/bin/arm-brcm-linux-uclibcgnueabi-gcc" \
-DCMAKE_CXX_COMPILER="/opt/brcm-arm/bin/arm-brcm-linux-uclibcgnueabi-g++" \
-DCMAKE_AR="/opt/brcm-arm/bin/arm-brcm-linux-uclibcgnueabi-ar" \
-DCMAKE_RANLIB="/opt/brcm-arm/bin/arm-brcm-linux-uclibcgnueabi-ranlib" \
-DCMAKE_STRIP="/opt/brcm-arm/bin/arm-brcm-linux-uclibcgnueabi-strip" \
-DCMAKE_C_FLAGS="$ARM_COMPILER_FLAGS" \
-DCMAKE_SHARED_LINKER_FLAGS="$ARM_LINKER_FLAGS" \
-DCMAKE_EXE_LINKER_FLAGS="$ARM_LINKER_FLAGS" \
-DCMAKE_C_LINK_EXECUTABLE="$ARM_LINK_EXECUTABLE" \
-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
-DCMAKE_VERBOSE_MAKEFILE=TRUE \
../

$MAKE
make install
touch ../__package_installed
fi

