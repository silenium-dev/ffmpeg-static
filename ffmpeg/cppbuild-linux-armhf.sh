#!/bin/bash

tar --totals -xjf ../alsa-lib-$ALSA_VERSION.tar.bz2

export CFLAGS="-I$INSTALL_PATH/include -L$INSTALL_PATH/lib"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
HOST_ARCH="$(uname -m)"
CROSSCOMPILE=1
if [[ $HOST_ARCH == *"arm"* ]]
then
  echo "Detected arm arch so not cross compiling";
  CROSSCOMPILE=0
else
  echo "Detected non arm arch so cross compiling";
fi

echo ""
echo "--------------------"
echo "Building zimg"
echo "--------------------"
echo ""
cd zimg-release-$ZIMG_VERSION
autoreconf -iv
./configure --prefix=$INSTALL_PATH --disable-frontend --disable-shared --with-pic --host=arm-linux-gnueabihf
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building zlib"
echo "--------------------"
echo ""
cd ../$ZLIB
CC="arm-linux-gnueabihf-gcc -fPIC" ./configure --prefix=$INSTALL_PATH --static
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building LAME"
echo "--------------------"
echo ""
cd ../$LAME
./configure --prefix=$INSTALL_PATH --disable-frontend --disable-shared --with-pic --host=arm-linux-gnueabihf
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building XML2"
echo "--------------------"
echo ""
cd ../$XML2
./configure --prefix=$INSTALL_PATH $LIBXML_CONFIG --host=arm-linux-gnueabihf
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building speex"
echo "--------------------"
echo ""
cd ../$SPEEX
PKG_CONFIG= ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=arm-linux-gnueabihf
make -j $MAKEJ V=0
make install
cd ../$OPUS
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=arm-linux-gnueabihf
make -j $MAKEJ V=0
make install
cd ../$OPENCORE_AMR
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=arm-linux-gnueabihf
make -j $MAKEJ V=0
make install
cd ../$VO_AMRWBENC
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=arm-linux-gnueabihf
make -j $MAKEJ V=0
make install
cd ../$OPENSSL
if [ $CROSSCOMPILE -eq 1 ]
then
  ./Configure linux-generic32 -fPIC no-shared --prefix=$INSTALL_PATH --libdir=lib --cross-compile-prefix=arm-linux-gnueabihf-
else
  ./Configure linux-generic32 -fPIC no-shared --prefix=$INSTALL_PATH --libdir=lib
fi
make -s -j $MAKEJ
make install_sw
cd ../srt-$LIBSRT_VERSION
if [ $CROSSCOMPILE -eq 1 ]
then
  $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $SRT_CONFIG -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv6 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ -DCMAKE_STRIP=arm-linux-gnueabihf-strip -DCMAKE_FIND_ROOT_PATH=arm-linux-gnueabihf .
else
  $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $SRT_CONFIG .
fi
make -j $MAKEJ V=0
make install
cd ../openh264-$OPENH264_VERSION
make -j $MAKEJ DESTDIR=./ PREFIX=.. AR=arm-linux-gnueabihf-ar ARCH=armhf USE_ASM=No install-static CC=arm-linux-gnueabihf-gcc CXX=arm-linux-gnueabihf-g++
cd ../$X264
if [ $CROSSCOMPILE -eq 1 ]
then
  ./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-opencl --disable-cli --host=arm-linux-gnueabihf --cross-prefix="arm-linux-gnueabihf-" --disable-asm
else
  ./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-opencl --disable-cli --disable-asm
fi
make -j $MAKEJ V=0
make install
cd ../x265-$X265/build/linux
# from x265 multilib.sh
mkdir -p 8bit 10bit 12bit

cd 12bit
if [ $CROSSCOMPILE -eq 1 ]
then
  $CMAKE ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv6 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_STRIP=arm-linux-gnueabihf-strip -DCMAKE_FIND_ROOT_PATH=arm-linux-gnueabihf -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF
  make -j $MAKEJ

  cd ../10bit
  $CMAKE ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv6 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_STRIP=arm-linux-gnueabihf-strip -DCMAKE_FIND_ROOT_PATH=arm-linux-gnueabihf -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF
  make -j $MAKEJ

  cd ../8bit
  ln -sf ../10bit/libx265.a libx265_main10.a
  ln -sf ../12bit/libx265.a libx265_main12.a
  $CMAKE ../../../source -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DENABLE_SHARED:BOOL=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv6 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_STRIP=arm-linux-gnueabihf-strip -DCMAKE_FIND_ROOT_PATH=arm-linux-gnueabihf -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF -DENABLE_CLI=OFF
else
  $CMAKE ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv6 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF
  make -j $MAKEJ

  cd ../10bit
  $CMAKE ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv6 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF
  make -j $MAKEJ

  cd ../8bit
  ln -sf ../10bit/libx265.a libx265_main10.a
  ln -sf ../12bit/libx265.a libx265_main12.a
  $CMAKE ../../../source -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DENABLE_SHARED:BOOL=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv6 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF -DENABLE_CLI=OFF
fi
make -j $MAKEJ

# rename the 8bit library, then combine all three into libx265.a
mv libx265.a libx265_main.a
ar -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
make install
# ----
cd ../../../
cd ../libvpx-$VPX_VERSION
patch -Np1 < ../../../libvpx-linux-arm.patch
if [ $CROSSCOMPILE -eq 1 ]
then
  CROSS=arm-linux-gnueabihf- ./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-examples --disable-unit-tests --target=armv7-linux-gcc
else
  ./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-examples --disable-unit-tests
fi
make -j $MAKEJ
make install
cd ../libwebp-$WEBP_VERSION
if [ $CROSSCOMPILE -eq 1 ]
then
  $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $WEBP_CONFIG -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv6 -DCMAKE_CXX_FLAGS="$CXXFLAGS -fPIC" -DCMAKE_C_FLAGS="$CFLAGS -fPIC" -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ -DCMAKE_STRIP=arm-linux-gnueabihf-strip -DCMAKE_FIND_ROOT_PATH=arm-linux-gnueabih .
else
  $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $WEBP_CONFIG .
fi
make -j $MAKEJ V=0
make -j $MAKEJ V=0
make install
cd ../alsa-lib-$ALSA_VERSION/
./configure --host=arm-linux-gnueabihf --prefix=$INSTALL_PATH --disable-python
make -j $MAKEJ V=0
make install
cd ../freetype-$FREETYPE_VERSION
./configure --prefix=$INSTALL_PATH --with-bzip2=no --with-harfbuzz=no --with-png=no --with-brotli=no --enable-static --disable-shared --with-pic --host=arm-linux-gnueabihf
make -j $MAKEJ
make install
cd ../nv-codec-headers-n$NVCODEC_VERSION
make install PREFIX=$INSTALL_PATH
cd ../libaom-$AOMAV1_VERSION
mkdir -p build_release
cd build_release
if [ $CROSSCOMPILE -eq 1 ]
then
  $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv6 -DCMAKE_CXX_FLAGS="$CXXFLAGS -fPIC" -DCMAKE_C_FLAGS="$CFLAGS -fPIC" -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ -DCMAKE_STRIP=arm-linux-gnueabihf-strip -DCMAKE_FIND_ROOT_PATH=arm-linux-gnueabih -DAOM_TARGET_CPU=generic $LIBAOM_CONFIG ..
else
  $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $LIBAOM_CONFIG ..
fi
make -j $MAKEJ
make install
cd ..
cd ../SVT-AV1-v$SVTAV1_VERSION
mkdir -p build_release
cd build_release
if [ $CROSSCOMPILE -eq 1 ]
then
  $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv6 -DCMAKE_CXX_FLAGS="$CXXFLAGS -fPIC" -DCMAKE_C_FLAGS="$CFLAGS -fPIC" -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ -DCMAKE_STRIP=arm-linux-gnueabihf-strip -DCMAKE_FIND_ROOT_PATH=arm-linux-gnueabih $LIBSVTAV1_CONFIG ..
else
  $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $LIBSVTAV1_CONFIG ..
fi
make -j $MAKEJ
make install
cd ..
cd ../ffmpeg-$FFMPEG_VERSION
if [ $CROSSCOMPILE -eq 1 ]
then
  if [[ ! -d $USERLAND_PATH ]]; then
    USERLAND_PATH="$(which arm-linux-gnueabihf-gcc | grep -o '.*/tools/')../userland"
  fi
  LDEXEFLAGS='-Wl,-rpath,\$$ORIGIN/' PKG_CONFIG_PATH=../lib/pkgconfig/ ./configure --prefix=.. $DISABLE $ENABLE $ENABLE_VULKAN --enable-omx --enable-mmal --enable-omx-rpi --enable-pthreads --enable-libxcb --enable-libpulse --cc="arm-linux-gnueabihf-gcc" --extra-cflags="$CFLAGS -I$USERLAND_PATH/ -I$USERLAND_PATH/interface/vmcs_host/khronos/IL/ -I$USERLAND_PATH/host_applications/linux/libs/bcm_host/include/ -I../include/ -I../include/libxml2 -I../include/mfx/ -I../include/svt-av1" --extra-ldflags="-L$USERLAND_PATH/build/lib/ -L../lib/" --extra-libs="-lstdc++ -lasound -lvchiq_arm -lvcsm -lvcos -lpthread -ldl -lz -lm" --enable-cross-compile --arch=armhf --target-os=linux --cross-prefix="arm-linux-gnueabihf-" || cat ffbuild/config.log
else
  LDEXEFLAGS='-Wl,-rpath,\$$ORIGIN/' PKG_CONFIG_PATH=../lib/pkgconfig/ ./configure --prefix=.. $DISABLE $ENABLE $ENABLE_VULKAN --enable-cuda --enable-cuvid --enable-nvenc --enable-omx --enable-mmal --enable-omx-rpi --enable-pthreads --enable-libxcb --enable-libpulse --extra-cflags="-I../include/ -I../include/libxml2 -I../include/mfx/ -I../include/svt-av1" --extra-ldflags="-L../lib/ -L/opt/vc/lib" --extra-libs="-lstdc++ -lasound -lvchiq_arm -lvcsm -lvcos -lpthread -ldl -lz -lm" || cat ffbuild/config.log
fi
make -j $MAKEJ
make install
