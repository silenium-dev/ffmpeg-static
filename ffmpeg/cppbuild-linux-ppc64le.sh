#!/bin/bash

MACHINE_TYPE=$( uname -m )
echo ""
echo "--------------------"
echo "Building zimg"
echo "--------------------"
echo ""
cd zimg-release-$ZIMG_VERSION
autoreconf -iv
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  CC="gcc -m64 -fPIC" ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic
else
  CC="powerpc64le-linux-gnu-gcc -m64 -fPIC" ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=powerpc64le-linux-gnu
fi
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building zlib"
echo "--------------------"
echo ""
cd ../$ZLIB
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  CC="gcc -m64 -fPIC" ./configure --prefix=$INSTALL_PATH --static
else
  CC="powerpc64le-linux-gnu-gcc -m64 -fPIC" ./configure --prefix=$INSTALL_PATH --static
fi
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building LAME"
echo "--------------------"
echo ""
cd ../$LAME
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  ./configure --prefix=$INSTALL_PATH --disable-frontend --disable-shared --with-pic --build=ppc64le-linux CFLAGS="-m64"
else
  CC="powerpc64le-linux-gnu-gcc -m64" CXX="powerpc64le-linux-gnu-g++ -m64" ./configure --host=powerpc64le-linux-gnu --prefix=$INSTALL_PATH --disable-shared --with-pic --build=ppc64le-linux CFLAGS="-m64"
fi
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building XML2"
echo "--------------------"
echo ""
cd ../$XML2
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  ./configure --prefix=$INSTALL_PATH $LIBXML_CONFIG --build=ppc64le-linux CFLAGS="-m64"
else
  CC="powerpc64le-linux-gnu-gcc -m64" CXX="powerpc64le-linux-gnu-g++ -m64" ./configure --host=powerpc64le-linux-gnu --prefix=$INSTALL_PATH $LIBXML_CONFIG --build=ppc64le-linux CFLAGS="-m64"
fi
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building speex"
echo "--------------------"
echo ""
cd ../$SPEEX
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  PKG_CONFIG= ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --build=ppc64le-linux CFLAGS="-m64"
else
  PKG_CONFIG= ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=powerpc64le-linux-gnu --build=ppc64le-linux CFLAGS="-m64"
fi
make -j $MAKEJ V=0
make install
cd ../$OPUS
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --build=ppc64le-linux CFLAGS="-m64" CXXFLAGS="-m64"
else
  ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=powerpc64le-linux-gnu --build=ppc64le-linux CFLAGS="-m64"
fi
make -j $MAKEJ V=0
make install
cd ../$OPENCORE_AMR
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --build=ppc64le-linux CFLAGS="-m64" CXXFLAGS="-m64"
else
  ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=powerpc64le-linux-gnu --build=ppc64le-linux CFLAGS="-m64"
fi
make -j $MAKEJ V=0
make install
cd ../$VO_AMRWBENC
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --build=ppc64le-linux CFLAGS="-m64" CXXFLAGS="-m64"
else
  ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=powerpc64le-linux-gnu --build=ppc64le-linux CFLAGS="-m64"
fi
make -j $MAKEJ V=0
make install
cd ../$OPENSSL
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  ./Configure linux-ppc64le -fPIC no-shared --prefix=$INSTALL_PATH --libdir=lib
else
  ./Configure linux-ppc64le -fPIC no-shared --cross-compile-prefix=powerpc64le-linux-gnu- --prefix=$INSTALL_PATH --libdir=lib
fi
make -s -j $MAKEJ
make install_sw
cd ../srt-$LIBSRT_VERSION
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $SRT_CONFIG .
else
  CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $SRT_CONFIG -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=ppc64le -DCMAKE_CXX_FLAGS="-m64" -DCMAKE_C_FLAGS="-m64" -DCMAKE_C_COMPILER=powerpc64le-linux-gnu-gcc -DCMAKE_CXX_COMPILER=powerpc64le-linux-gnu-g++ -DCMAKE_STRIP=powerpc64le-linux-gnu-strip -DCMAKE_FIND_ROOT_PATH=powerpc64le-linux-gnu .
fi
make -j $MAKEJ V=0
make install
cd ../openh264-$OPENH264_VERSION
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  make -j $MAKEJ DESTDIR=./ PREFIX=.. AR=ar ARCH=ppc64le USE_ASM=No install-static
else
  make -j $MAKEJ DESTDIR=./ PREFIX=.. AR=powerpc64le-linux-gnu-ar ARCH=ppc64le USE_ASM=No install-static CC=powerpc64le-linux-gnu-gcc CXX=powerpc64le-linux-gnu-g++
fi
cd ../$X264
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  ./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-opencl --host=ppc64le-linux
else
  CC="powerpc64le-linux-gnu-gcc -m64" CXX="powerpc64le-linux-gnu-g++ -m64" ./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-opencl --build=ppc64le-linux --host=ppc64le-linux
fi
make -j $MAKEJ V=0
make install

cd ../x265-$X265/build/linux
# from x265 multilib.sh
mkdir -p 8bit 10bit 12bit

cd 12bit
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  CC="gcc -m64" CXX="g++ -m64" $CMAKE ../../../source -DENABLE_ALTIVEC=OFF -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON -DENABLE_LIBNUMA=OFF -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF
  make -j $MAKEJ

  cd ../10bit
  CC="gcc -m64" CXX="g++ -m64" $CMAKE ../../../source -DENABLE_ALTIVEC=OFF -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF
  make -j $MAKEJ

  cd ../8bit
  ln -sf ../10bit/libx265.a libx265_main10.a
  ln -sf ../12bit/libx265.a libx265_main12.a
  CC="gcc -m64" CXX="g++ -m64" $CMAKE ../../../source -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DENABLE_SHARED:BOOL=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF -DENABLE_CLI=OFF
else
  $CMAKE ../../../source -DENABLE_ALTIVEC=OFF -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DMAIN12=ON -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=ppc64le -DCMAKE_CXX_FLAGS="-m64" -DCMAKE_C_FLAGS="-m64" -DCMAKE_C_COMPILER=powerpc64le-linux-gnu-gcc -DCMAKE_CXX_COMPILER=powerpc64le-linux-gnu-g++ -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_STRIP=powerpc64le-linux-gnu-strip -DCMAKE_FIND_ROOT_PATH=powerpc64le-linux-gnu -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF
  make -j $MAKEJ

  cd ../10bit
  $CMAKE ../../../source -DENABLE_ALTIVEC=OFF -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=ppc64le -DCMAKE_CXX_FLAGS="-m64" -DCMAKE_C_FLAGS="-m64" -DCMAKE_C_COMPILER=powerpc64le-linux-gnu-gcc -DCMAKE_CXX_COMPILER=powerpc64le-linux-gnu-g++ -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_STRIP=powerpc64le-linux-gnu-strip -DCMAKE_FIND_ROOT_PATH=powerpc64le-linux-gnu -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF
  make -j $MAKEJ

  cd ../8bit
  ln -sf ../10bit/libx265.a libx265_main10.a
  ln -sf ../12bit/libx265.a libx265_main12.a
  $CMAKE ../../../source -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DENABLE_SHARED:BOOL=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=ppc64le -DCMAKE_CXX_FLAGS="-m64" -DCMAKE_C_FLAGS="-m64" -DCMAKE_C_COMPILER=powerpc64le-linux-gnu-gcc -DCMAKE_CXX_COMPILER=powerpc64le-linux-gnu-g++ -DCMAKE_CXX_FLAGS=-fPIC -DCMAKE_STRIP=powerpc64le-linux-gnu-strip -DCMAKE_FIND_ROOT_PATH=powerpc64le-linux-gnu -DCMAKE_BUILD_TYPE=Release -DENABLE_ASSEMBLY=OFF -DENABLE_CLI=OFF
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
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  ./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-examples --disable-unit-tests --target=generic-gnu
else
  CC="powerpc64le-linux-gnu-gcc -m64" CXX="powerpc64le-linux-gnu-g++ -m64" ./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-examples --disable-unit-tests --target=generic-gnu
fi
make -j $MAKEJ
make install
cd ../libwebp-$WEBP_VERSION
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $WEBP_CONFIG .
else
  CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $WEBP_CONFIG -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=ppc64le -DCMAKE_CXX_FLAGS="-m64 -fPIC" -DCMAKE_C_FLAGS="-m64 -fPIC" -DCMAKE_C_COMPILER=powerpc64le-linux-gnu-gcc -DCMAKE_CXX_COMPILER=powerpc64le-linux-gnu-g++ -DCMAKE_STRIP=powerpc64le-linux-gnu-strip -DCMAKE_FIND_ROOT_PATH=powerpc64le-linux-gnu .
fi
make -j $MAKEJ V=0
make install
cd ../freetype-$FREETYPE_VERSION
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  ./configure --prefix=$INSTALL_PATH --with-bzip2=no --with-harfbuzz=no --with-png=no --with-brotli=no --enable-static --disable-shared --with-pic --target=ppc64le-linux CFLAGS="-m64"
else
  CC="powerpc64le-linux-gnu-gcc" CXX="powerpc64le-linux-gnu-g++" ./configure --prefix=$INSTALL_PATH --with-bzip2=no --with-harfbuzz=no --with-png=no --with-brotli=no --enable-static --disable-shared --with-pic --host=powerpc64le-linux-gnu --build=ppc64le-linux CFLAGS="-m64"
fi
make -j $MAKEJ
make install
cd ../nv-codec-headers-n$NVCODEC_VERSION
make install PREFIX=$INSTALL_PATH
cd ../libaom-$AOMAV1_VERSION
mkdir -p build_release
cd build_release
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $LIBAOM_CONFIG ..
else
  CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=ppc64le -DCMAKE_CXX_FLAGS="-m64 -fPIC" -DCMAKE_C_FLAGS="-m64 -fPIC" -DCMAKE_C_COMPILER=powerpc64le-linux-gnu-gcc -DCMAKE_CXX_COMPILER=powerpc64le-linux-gnu-g++ -DCMAKE_STRIP=powerpc64le-linux-gnu-strip -DCMAKE_FIND_ROOT_PATH=powerpc64le-linux-gnu $LIBAOM_CONFIG ..
fi
make -j $MAKEJ
make install
cd ..
cd ../SVT-AV1-v$SVTAV1_VERSION
mkdir -p build_release
cd build_release
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $LIBSVTAV1_CONFIG ..
else
  CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=ppc64le -DCMAKE_CXX_FLAGS="-m64 -fPIC" -DCMAKE_C_FLAGS="-m64 -fPIC" -DCMAKE_C_COMPILER=powerpc64le-linux-gnu-gcc -DCMAKE_CXX_COMPILER=powerpc64le-linux-gnu-g++ -DCMAKE_STRIP=powerpc64le-linux-gnu-strip -DCMAKE_FIND_ROOT_PATH=powerpc64le-linux-gnu $LIBSVTAV1_CONFIG ..
fi
make -j $MAKEJ
make install
cd ..
cd ../ffmpeg-$FFMPEG_VERSION
if [[ "$MACHINE_TYPE" =~ ppc64 ]]; then
  LDEXEFLAGS='-Wl,-rpath,\$$ORIGIN/' PKG_CONFIG_PATH=../lib/pkgconfig/ ./configure --prefix=.. $DISABLE $ENABLE $ENABLE_VULKAN --enable-cuda --enable-cuvid --enable-nvenc --enable-pthreads --enable-libxcb --enable-libpulse --cc="gcc -m64" --extra-cflags="-I../include/ -I../include/libxml2 -I../include/mfx -I../include/svt-av1" --extra-ldflags="-L../lib/" --extra-libs="-lstdc++ -ldl -lz -lm" --disable-altivec || cat ffbuild/config.log
else
  echo "configure ffmpeg cross compile"
  LDEXEFLAGS='-Wl,-rpath,\$$ORIGIN/' PKG_CONFIG_PATH=../lib/pkgconfig/:/usr/lib/powerpc64le-linux-gnu/pkgconfig/ ./configure --prefix=.. $DISABLE $ENABLE $ENABLE_VULKAN --enable-cuda --enable-cuvid --enable-nvenc --enable-pthreads --enable-libxcb --enable-libpulse --cc="powerpc64le-linux-gnu-gcc -m64" --extra-cflags="-I../include/ -I../include/libxml2 -I../include/mfx -I../include/svt-av1" --extra-ldflags="-L../lib/" --enable-cross-compile --target-os=linux --arch=ppc64le-linux --extra-libs="-lstdc++ -lpthread -ldl -lz -lm" --disable-altivec || cat ffbuild/config.log
fi
make -j $MAKEJ
make install
