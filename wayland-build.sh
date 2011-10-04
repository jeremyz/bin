#!/bin/bash

# hbased on ttp://wayland.freedesktop.org/building.html

WLD=/opt/wayland
LD_LIBRARY_PATH=$WLD/lib
PKG_CONFIG_PATH=$WLD/lib/pkgconfig/:$WLD/share/pkgconfig/
ACLOCAL="aclocal -I $WLD/share/aclocal"
C_INCLUDE_PATH=$WLD/include
LIBRARY_PATH=$WLD/lib
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1

export WLD LD_LIBRARY_PATH PKG_CONFIG_PATH ACLOCAL C_INCLUDE_PATH LIBRARY_PATH PKG_CONFIG_ALLOW_SYSTEM_CFLAGS

BUILD_DIR=${BUILD_DIR:-~/usr/git/wayland}
FORCE_AUTOGEN=0
for arg in $@; do if [ "$arg"="-f" ]; then FORCE_AUTOGEN=1; fi; done

[ ! -d "$WLD/share/aclocal" ] && sudo mkdir -p "$WLD/share/aclocal"

RESET="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"

function say () { echo -e "$GREEN$1$RESET"; }
function error () { echo -e "${RED}FAILURE${RESET}" && exit 1; }

function build () {
    say " * make" && make && say " * install" && sudo -E make install
}

function autogen () {
    say " * autogen --prefix=$WLD $my_configure_opts" && ./autogen.sh --prefix=$WLD $my_configure_opts && build
}

function update () {
    SHA_PREV=$(git log --pretty="format:%H" HEAD~1..)
    say " * pull" && git pull || return 1
    SHA_HEAD=$(git log --pretty="format:%H" HEAD~1..)
    if [ $FORCE_AUTOGEN -eq 1 ]; then
        autogen
    else
        [ "$SHA_PREV" = "$SHA_HEAD" ] && return 0
        build
    fi
}

function do_your_job () {
    if [ -d "$my_dir" ]; then
        cd "$my_dir" && update && cd .. || error
    else
        say " * clone $my_src" && git clone "$my_src" "$my_dir" && cd "$my_dir" && autogen && cd .. || error
    fi
    say " * SUCCESS\n"
}

cd $BUILD_DIR || exit 1

# WAYLAND
say "wayland"
my_dir=wayland
my_src=git://anongit.freedesktop.org/wayland/wayland
my_configure_opts=
do_your_job

# XCB
[ ! -d xcb ] && mkdir xcb
cd xcb

say "cxb:pthread-stubs"
my_dir=pthread-stubs
my_src=git://anongit.freedesktop.org/xcb/pthread-stubs
my_configure_opts=
do_your_job

cd ..

# MESA
[ ! -d mesa ] && mkdir mesa
cd mesa

say "mesa:drm"
my_dir=drm
my_src=git://anongit.freedesktop.org/git/mesa/drm
my_configure_opts="--enable-nouveau-experimental-api"
do_your_job

say "mesa:macros"
my_dir=macros
my_src=git://anongit.freedesktop.org/git/xorg/util/macros
my_configure_opts=
do_your_job

say "mesa:glproto"
my_dir=glproto
my_src=git://anongit.freedesktop.org/xorg/proto/glproto
my_configure_opts=
do_your_job

say "mesa:dri2proto"
my_dir=dri2proto
my_src=git://anongit.freedesktop.org/xorg/proto/dri2proto
my_configure_opts=
do_your_job

say "mesa:mesa"
my_dir=mesa
my_src=git://anongit.freedesktop.org/mesa/mesa
my_configure_opts="--enable-gles2 --disable-gallium-egl --with-egl-platforms=x11,wayland,drm --enable-gbm --enable-shared-glapi"
do_your_job

cd ..

# XORG
[ ! -d xorg ] && mkdir xorg
cd xorg

say "xorg:macros"
my_dir=macros
my_src=git://anongit.freedesktop.org/xorg/util/macros
my_configure_opts=
do_your_job

say "xorg:xproto"
my_dir=xproto
my_src=git://anongit.freedesktop.org/xorg/proto/xproto
my_configure_opts=
do_your_job

say "xorg:kbproto"
my_dir=kbproto
my_src=git://anongit.freedesktop.org/xorg/proto/kbproto
my_configure_opts=
do_your_job

say "xorg:libX11"
my_dir=libX11
my_src=git://anongit.freedesktop.org/xorg/lib/libX11
my_configure_opts="--enable-specs=false"
do_your_job

say "xorg:libxkbcommon"
my_dir=libxkbcommon
my_src=git://people.freedesktop.org/xorg/lib/libxkbcommon.git
my_configure_opts="--with-xkb-config-root=/usr/share/X11/xkb --enable-specs=false"
do_your_job

say "xorg:pixman"
my_dir=pixman
my_src=git://anongit.freedesktop.org/pixman
my_configure_opts=
do_your_job

say "xorg:cairo"
my_dir=cairo
my_src=git://anongit.freedesktop.org/cairo
my_configure_opts="--enable-gl --enable-xcb"
do_your_job

cd ..

# WAYLAND-DEMOS
say "wayland-demos"
my_dir=wayland-demos
my_src=git://anongit.freedesktop.org/wayland/wayland-demos
my_configure_opts=
do_your_job

say "DONE"

