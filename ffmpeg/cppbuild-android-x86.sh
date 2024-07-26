#!/bin/bash

export AR="$ANDROID_PREFIX-ar"
export RANLIB="$ANDROID_PREFIX-ranlib"
export CC="$ANDROID_CC $ANDROID_FLAGS"
export CXX="$ANDROID_CC++ $ANDROID_FLAGS"
export STRIP="$ANDROID_PREFIX-strip"
echo ""
echo "--------------------"
echo "Building zimg"
echo "--------------------"
echo ""
cd zimg-release-$ZIMG_VERSION
autoreconf -iv
./configure --prefix=$INSTALL_PATH --disable-frontend --disable-shared --with-pic --host=i686-linux
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building zlib"
echo "--------------------"
echo ""
cd ../$ZLIB
./configure --prefix=$INSTALL_PATH --static --uname=i686-linux
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building LAME"
echo "--------------------"
echo ""
cd ../$LAME
./configure --prefix=$INSTALL_PATH --disable-frontend --disable-shared --with-pic --host=i686-linux
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building XML2"
echo "--------------------"
echo ""
cd ../$XML2
./configure --prefix=$INSTALL_PATH $LIBXML_CONFIG --host=i686-linux
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building speex"
echo "--------------------"
echo ""
cd ../$SPEEX
PKG_CONFIG= ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=i686-linux
cd libspeex
make -j $MAKEJ V=0
make install
cd ../include
make install
cd ../../$OPUS
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=i686-linux
make -j $MAKEJ V=0
make install
cd ../$OPENCORE_AMR
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=i686-linux
make -j $MAKEJ V=0
make install
cd ../$VO_AMRWBENC
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic --host=i686-linux
make -j $MAKEJ V=0
make install
cd ../$OPENSSL
PATH="${ANDROID_CC%/*}:$ANDROID_BIN/bin:$PATH" ./Configure --prefix=$INSTALL_PATH --libdir=lib android-x86 no-shared no-tests -D__ANDROID_API__=24
ANDROID_DEV="$ANDROID_ROOT/usr" make -s -j $MAKEJ
make install_dev
cd ../srt-$LIBSRT_VERSION
patch -Np1 < ../../../srt-android.patch || true
$CMAKE -DCMAKE_TOOLCHAIN_FILE=${PLATFORM_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_ABI=x86 -DANDROID_NATIVE_API_LEVEL=24 -DCMAKE_C_FLAGS="-I$INSTALL_PATH/include/" -DCMAKE_CXX_FLAGS="-I$INSTALL_PATH/include/" -DCMAKE_EXE_LINKER_FLAGS="-L$INSTALL_PATH/lib/" -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $SRT_CONFIG .
make -j $MAKEJ V=0
make install
cd ../openh264-$OPENH264_VERSION
sedinplace 's/stlport_shared/system/g' codec/build/android/dec/jni/Application.mk build/platform-android.mk
sedinplace 's/12/24/g' codec/build/android/dec/jni/Application.mk build/platform-android.mk
CFLAGS="$ANDROID_FLAGS" LDFLAGS="$ANDROID_FLAGS" make -j $MAKEJ PREFIX=$INSTALL_PATH OS=android ARCH=x86 USE_ASM=No NDKROOT="$ANDROID_NDK" NDK_TOOLCHAIN_VERSION="clang" TARGET="android-24" install-static
cd ../$X264
patch -Np1 < ../../../x264-android.patch || true
./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-cli --cross-prefix="$ANDROID_PREFIX-" --sysroot="$ANDROID_ROOT" --host=i686-linux --disable-asm
make -j $MAKEJ V=0
make install
cd ../x265-$X265
patch -Np1 < ../../../x265-android.patch || true
cd build/linux
# from x265 multilib.sh
mkdir -p 8bit 10bit 12bit

cd 12bit
$CMAKE ../../../source -DCMAKE_TOOLCHAIN_FILE=${PLATFORM_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_ABI=x86 -DANDROID_NATIVE_API_LEVEL=24 -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_ASSEMBLY=OFF -DMAIN12=ON -DENABLE_LIBNUMA=OFF -DCMAKE_BUILD_TYPE=Release -DNASM_EXECUTABLE:FILEPATH=$INSTALL_PATH/bin/nasm
make -j $MAKEJ

cd ../10bit
$CMAKE ../../../source -DCMAKE_TOOLCHAIN_FILE=${PLATFORM_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_ABI=x86 -DANDROID_NATIVE_API_LEVEL=24 -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_ASSEMBLY=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_BUILD_TYPE=Release -DNASM_EXECUTABLE:FILEPATH=$INSTALL_PATH/bin/nasm
make -j $MAKEJ

cd ../8bit
ln -sf ../10bit/libx265.a libx265_main10.a
ln -sf ../12bit/libx265.a libx265_main12.a
$CMAKE ../../../source -DCMAKE_TOOLCHAIN_FILE=${PLATFORM_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_ABI=x86 -DANDROID_NATIVE_API_LEVEL=24 -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DENABLE_SHARED:BOOL=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_BUILD_TYPE=Release -DENABLE_CLI=OFF -DENABLE_ASSEMBLY=OFF
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
patch -Np1 < ../../../libvpx-android.patch
CFLAGS="$ANDROID_FLAGS" CXXFLAGS="$ANDROID_FLAGS" LDFLAGS="$ANDROID_FLAGS" ./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-examples --disable-unit-tests --disable-tools --target=x86-android-gcc --as=nasm
make -j $MAKEJ
make install
cd ../libwebp-$WEBP_VERSION
$CMAKE -DCMAKE_TOOLCHAIN_FILE=${PLATFORM_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_ABI=x86 -DANDROID_NATIVE_API_LEVEL=24 -DCMAKE_C_FLAGS="-I$INSTALL_PATH/include/" -DCMAKE_CXX_FLAGS="-I$INSTALL_PATH/include/" -DCMAKE_EXE_LINKER_FLAGS="-L$INSTALL_PATH/lib/" -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $WEBP_CONFIG .
make -j $MAKEJ V=0
make install
cd ../freetype-$FREETYPE_VERSION
./configure --prefix=$INSTALL_PATH --with-bzip2=no --with-harfbuzz=no --with-png=no --with-brotli=no --enable-static --disable-shared --with-pic --host=i686-linux
make -j $MAKEJ
make install
cd ../libaom-$AOMAV1_VERSION
mkdir -p build_release
cd build_release
$CMAKE -DCMAKE_TOOLCHAIN_FILE=${PLATFORM_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_ABI=x86 -DANDROID_NATIVE_API_LEVEL=24 -DCMAKE_C_FLAGS="-I$INSTALL_PATH/include/" -DCMAKE_CXX_FLAGS="-I$INSTALL_PATH/include/" -DCMAKE_EXE_LINKER_FLAGS="-L$INSTALL_PATH/lib/" -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $LIBAOM_CONFIG ..
make -j $MAKEJ
make install
cd ..
cd ../SVT-AV1-v$SVTAV1_VERSION
mkdir -p build_release
cd build_release
$CMAKE -DCMAKE_TOOLCHAIN_FILE=${PLATFORM_ROOT}/build/cmake/android.toolchain.cmake -DANDROID_ABI=x86 -DANDROID_NATIVE_API_LEVEL=24 -DCMAKE_C_FLAGS="-I$INSTALL_PATH/include/" -DCMAKE_CXX_FLAGS="-I$INSTALL_PATH/include/" -DCMAKE_EXE_LINKER_FLAGS="-L$INSTALL_PATH/lib/" -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $LIBSVTAV1_CONFIG ..
make -j $MAKEJ
make install
cd ..
cd ../ffmpeg-$FFMPEG_VERSION
sedinplace 's/unsigned long int/unsigned int/g' libavdevice/v4l2.c
LDEXEFLAGS='-Wl,-rpath,\$$ORIGIN/' ./configure --prefix=.. $DISABLE $ENABLE --enable-jni --enable-mediacodec --enable-pthreads --enable-cross-compile --cross-prefix="$ANDROID_PREFIX-" --ar="$AR" --ranlib="$RANLIB" --cc="$CC" --strip="$STRIP" --sysroot="$ANDROID_ROOT" --target-os=android --arch=atom --extra-cflags="-I../include/ -I../include/libxml2 -I../include/mfx -I../include/svt-av1 $ANDROID_FLAGS" --extra-ldflags="-L../lib/ $ANDROID_FLAGS" --extra-libs="$ANDROID_LIBS -lz -latomic" --disable-symver || cat ffbuild/config.log
make -j $MAKEJ
make install
