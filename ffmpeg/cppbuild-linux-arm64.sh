#!/bin/bash

tar --totals -xjf ../alsa-lib-$ALSA_VERSION.tar.bz2

export CFLAGS="-march=armv8-a+crypto -mcpu=cortex-a57+crypto -I$INSTALL_PATH/include -L$INSTALL_PATH/lib"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
HOST_ARCH="$(uname -m)"
echo ""
echo "--------------------"
echo "Building zimg"
echo "--------------------"
echo ""
cd zimg-release-$ZIMG_VERSION
autoreconf -iv
./configure --prefix=$INSTALL_PATH --disable-frontend --disable-shared --with-pic --host=aarch64-linux-gnu
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building zlib"
echo "--------------------"
echo ""
cd ../$ZLIB
CC="aarch64-linux-gnu-gcc -fPIC" ./configure --prefix=$INSTALL_PATH --static
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building LAME"
echo "--------------------"
echo ""
cd ../$LAME
./configure --prefix=$INSTALL_PATH --disable-frontend --disable-shared --with-pic --host=aarch64-linux-gnu
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building XML2"
echo "--------------------"
echo ""
cd ../$XML2
./configure --prefix=$INSTALL_PATH $LIBXML_CONFIG --host=aarch64-linux-gnu
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building speex"
echo "--------------------"
echo ""
cd ../$SPEEX
PKG_CONFIG= ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=aarch64-linux-gnu
make -j $MAKEJ V=0
make install
cd ../$OPUS
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=aarch64-linux-gnu
make -j $MAKEJ V=0
make install
cd ../$OPENCORE_AMR
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=aarch64-linux-gnu
make -j $MAKEJ V=0
make install
cd ../$VO_AMRWBENC
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=aarch64-linux-gnu
make -j $MAKEJ V=0
make install
cd ../$OPENSSL
./Configure linux-aarch64 -fPIC --prefix=$INSTALL_PATH --libdir=lib --cross-compile-prefix=aarch64-linux-gnu- "$CFLAGS" no-shared
make -s -j $MAKEJ
make install_sw
cd ../srt-$LIBSRT_VERSION
CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $SRT_CONFIG -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv8 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ .
make -j $MAKEJ V=0
make install
cd ../openh264-$OPENH264_VERSION
make -j $MAKEJ DESTDIR=./ PREFIX=.. OS=linux ARCH=arm64 USE_ASM=No install-static CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++
cd ../$X264
LDFLAGS="-Wl,-z,relro" ./configure --prefix=$INSTALL_PATH --enable-pic --enable-static --disable-shared --disable-opencl --disable-cli --enable-asm --host=aarch64-linux-gnu --extra-cflags="$CFLAGS -fno-aggressive-loop-optimizations" --cross-prefix="aarch64-linux-gnu-"
make -j $MAKEJ V=0
make install
cd ../x265-$X265/build/linux
# from x265 multilib.sh
mkdir -p 8bit 10bit 12bit

cd 12bit
$CMAKE ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv8 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF
make -j $MAKEJ

cd ../10bit
$CMAKE ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv8 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF
make -j $MAKEJ

cd ../8bit
ln -sf ../10bit/libx265.a libx265_main10.a
ln -sf ../12bit/libx265.a libx265_main12.a
$CMAKE ../../../source -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DENABLE_SHARED:BOOL=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv8 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF -DENABLE_CLI=OFF
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
sedinplace '/neon_i8mm/d' ./configure
CROSS=aarch64-linux-gnu- ./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-examples --disable-unit-tests --target=armv8-linux-gcc
sedinplace 's/HAS_NEON_I8MM (1 << 2)/HAS_NEON_I8MM 0/g' vpx_ports/*.h
sedinplace 's/#if HAVE_NEON_I8MM/#if 0/g' test/*.c* vpx_ports/*.c*
sedinplace 's/flags & HAS_NEON_I8MM/0/g' *.h
make -j $MAKEJ
make install
cd ../libwebp-$WEBP_VERSION
CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $WEBP_CONFIG -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv8 -DCMAKE_CXX_FLAGS="$CXXFLAGS -fPIC" -DCMAKE_C_FLAGS="$CFLAGS -fPIC" -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ .
make -j $MAKEJ V=0
make install
cd ../alsa-lib-$ALSA_VERSION/
./configure --host=aarch64-linux-gnu --prefix=$INSTALL_PATH --disable-python
make -j $MAKEJ V=0
make install
cd ../freetype-$FREETYPE_VERSION
./configure --prefix=$INSTALL_PATH --with-bzip2=no --with-harfbuzz=no --with-png=no --with-brotli=no --enable-static --disable-shared --with-pic --host=aarch64-linux-gnu
make -j $MAKEJ
make install
cd ../nv-codec-headers-n$NVCODEC_VERSION
make install PREFIX=$INSTALL_PATH
cd ../libaom-$AOMAV1_VERSION
mkdir -p build_release
cd build_release
CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv8 -DCMAKE_CXX_FLAGS="$CXXFLAGS -fPIC" -DCMAKE_C_FLAGS="$CFLAGS -fPIC" -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ $LIBAOM_CONFIG ..
make -j $MAKEJ
make install
cd ..
cd ../SVT-AV1-v$SVTAV1_VERSION
mkdir -p build_release
cd build_release
CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=armv8 -DCMAKE_CXX_FLAGS="$CXXFLAGS -fPIC" -DCMAKE_C_FLAGS="$CFLAGS -fPIC" -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ $LIBSVTAV1_CONFIG ..
make -j $MAKEJ
make install
cd ..
cd ../ffmpeg-$FFMPEG_VERSION
if [[ ! -d $USERLAND_PATH ]]; then
  USERLAND_PATH="$(which aarch64-linux-gnu-gcc | grep -o '.*/tools/')../userland"
fi
LDEXEFLAGS='-Wl,-rpath,\$$ORIGIN/' PKG_CONFIG_PATH=../lib/pkgconfig/ ./configure --prefix=.. $DISABLE $ENABLE $ENABLE_VULKAN --enable-cuda --enable-cuvid --enable-nvenc --enable-omx `#--enable-mmal` --enable-omx-rpi --enable-pthreads --enable-libxcb --enable-libpulse --cc="aarch64-linux-gnu-gcc" --extra-cflags="$CFLAGS -I$USERLAND_PATH/ -I$USERLAND_PATH/interface/vmcs_host/khronos/IL/ -I$USERLAND_PATH/host_applications/linux/libs/bcm_host/include/ -I../include/ -I../include/libxml2 -I../include/mfx/ -I../include/svt-av1 -fno-aggressive-loop-optimizations" --extra-ldflags="-Wl,-z,relro -L$USERLAND_PATH/build/lib/ -L../lib/" --extra-libs="-lstdc++ -lasound -lvchiq_arm `#-lvcsm` -lvcos -lpthread -ldl -lz -lm" --enable-cross-compile --arch=arm64 --target-os=linux --cross-prefix="aarch64-linux-gnu-" || cat ffbuild/config.log
make -j $MAKEJ
make install
