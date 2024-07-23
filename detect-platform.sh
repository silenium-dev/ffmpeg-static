#!/bin/bash

KERNEL=(`uname -s | tr '[A-Z]' '[a-z]'`)
ARCH=(`uname -m | tr '[A-Z]' '[a-z]'`)
case $KERNEL in
    darwin)
        OS=macosx
        ;;
    mingw32*)
        OS=windows
        KERNEL=windows
        ARCH=x86
        ;;
    mingw64*)
        OS=windows
        KERNEL=windows
        ARCH=x86_64
        ;;
    *)
        OS=$KERNEL
        ;;
esac
case $ARCH in
    arm64)
        ARCH=arm64
        ;;
    arm*)
        ARCH=arm
        ;;
    aarch64*)
        ARCH=arm64
        ;;
    i386|i486|i586|i686)
        ARCH=x86
        ;;
    amd64|x86-64)
        ARCH=x86_64
        ;;
esac
echo "$OS-$ARCH"
