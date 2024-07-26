#!/bin/bash

export AS="nasm"
export CC="gcc -m64 -fPIC"
export CXX="g++ -m64 -fPIC"
export LDFLAGS="-m64"
export LD="g++ -m64 -fPIC"
echo ""
echo "--------------------"
echo "Building zimg"
echo "--------------------"
echo ""
cd zimg-release-$ZIMG_VERSION
autoreconf -iv
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building zlib"
echo "--------------------"
echo ""
cd ../$ZLIB
./configure --prefix=$INSTALL_PATH --static CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building LAME"
echo "--------------------"
echo ""
cd ../$LAME
./configure --prefix=$INSTALL_PATH --disable-frontend --disable-shared --with-pic CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building XML2"
echo "--------------------"
echo ""
cd ../$XML2
./configure --prefix=$INSTALL_PATH $LIBXML_CONFIG CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ V=0
make install
echo ""
echo "--------------------"
echo "Building speex"
echo "--------------------"
echo ""
cd ../$SPEEX
PKG_CONFIG= ./configure --prefix=$INSTALL_PATH --disable-shared --with-pic CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ V=0
make install
cd ../$OPUS
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ V=0
make install
cd ../$OPENCORE_AMR
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ V=0
make install
cd ../$VO_AMRWBENC
./configure --prefix=$INSTALL_PATH --disable-shared --with-pic CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ V=0
make install
cd ../$OPENSSL
CC=gcc CXX=g++ LD=g++ ./Configure linux-elf -m64 -fPIC no-shared --prefix=$INSTALL_PATH --libdir=lib
make -s -j $MAKEJ
make install_sw
cd ../srt-$LIBSRT_VERSION
CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $SRT_CONFIG .
make -j $MAKEJ V=0
make install
cd ../openh264-$OPENH264_VERSION
make -j $MAKEJ DESTDIR=./ PREFIX=.. AR=ar ARCH=x86 USE_ASM=No install-static
cd ../$X264
./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-opencl CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ V=0
make install
cd ../x265-$X265/build/linux
# from x265 multilib.sh
mkdir -p 8bit 10bit 12bit

cd 12bit
$CMAKE ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_ASSEMBLY=OFF -DMAIN12=ON -DENABLE_LIBNUMA=OFF -DCMAKE_BUILD_TYPE=Release -DNASM_EXECUTABLE:FILEPATH=$INSTALL_PATH/bin/nasm
make -j $MAKEJ

cd ../10bit
$CMAKE ../../../source -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF -DENABLE_ASSEMBLY=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_BUILD_TYPE=Release -DNASM_EXECUTABLE:FILEPATH=$INSTALL_PATH/bin/nasm
make -j $MAKEJ

cd ../8bit
ln -sf ../10bit/libx265.a libx265_main10.a
ln -sf ../12bit/libx265.a libx265_main12.a
$CMAKE ../../../source -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DENABLE_SHARED:BOOL=OFF -DENABLE_LIBNUMA=OFF -DCMAKE_BUILD_TYPE=Release -DNASM_EXECUTABLE:FILEPATH=$INSTALL_PATH/bin/nasm -DENABLE_CLI=OFF
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
./configure --prefix=$INSTALL_PATH --enable-static --enable-pic --disable-examples --disable-unit-tests --target=x86-linux-gcc --as=nasm  CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ
make install
cd ../libwebp-$WEBP_VERSION
CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $WEBP_CONFIG .
make -j $MAKEJ V=0
make install
cd ../freetype-$FREETYPE_VERSION
./configure --prefix=$INSTALL_PATH --with-bzip2=no --with-harfbuzz=no --with-png=no --with-brotli=no --enable-static --disable-shared --with-pic CC="$CC" CXX="$CXX" LD="$LD" LDFLAGS="$LDFLAGS"
make -j $MAKEJ
make install
LIBS=
if [[ ! -z $(ldconfig -p | grep libva-drm) ]]; then
    cd ../libvpl-$VPL_VERSION
    PKG_CONFIG_PATH=../lib/pkgconfig cmake -B _build -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_BUILD_TYPE=Release
    cmake --build _build
    cmake --install _build
    ENABLE="$ENABLE --enable-libvpl"
    LIBS="-lva-drm -lva-x11 -lva"
fi
cd ../nv-codec-headers-n$NVCODEC_VERSION
make install PREFIX=$INSTALL_PATH
cd ../libaom-$AOMAV1_VERSION
mkdir -p build_release
cd build_release
CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $LIBAOM_CONFIG ..
make -j $MAKEJ
make install
cd ..
cd ../SVT-AV1-v$SVTAV1_VERSION
mkdir -p build_release
cd build_release
CFLAGS="-I$INSTALL_PATH/include/" CXXFLAGS="-I$INSTALL_PATH/include/" LDFLAGS="-L$INSTALL_PATH/lib/" $CMAKE -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH $LIBSVTAV1_CONFIG ..
make -j $MAKEJ
make install
cd ..
cd ../ffmpeg-$FFMPEG_VERSION
LDEXEFLAGS='-Wl,-rpath,\$$ORIGIN/' PKG_CONFIG_PATH=../lib/pkgconfig/ ./configure --prefix=.. $DISABLE $ENABLE $ENABLE_VULKAN --enable-libdrm --enable-cuda --enable-cuvid --enable-nvenc --enable-pthreads --enable-libxcb --enable-libpulse --cc="$CC -D__ILP32__" --extra-cflags="-I../include/ -I../include/libxml2 -I../include/vpl -I../include/svt-av1" --extra-ldflags="-L../lib/" --extra-libs="-lstdc++ -lpthread -ldl -lz -lm $LIBS" || cat ffbuild/config.log
make -j $MAKEJ
make install
