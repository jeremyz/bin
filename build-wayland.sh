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

[ ! -d "$WLD/share/aclocal" ] && sudo mkdir -p "$WLD/share/aclocal"

RESET="\033[0m"
RED="\033[0;31m"
function say () { echo -e "$RED$1$RESET"; }

# WAYLAND
say "wayland" && [ ! -d wayland ] && git clone git://anongit.freedesktop.org/wayland/wayland
cd wayland && git pull && ./autogen.sh --prefix=$WLD && make && sudo -E make install && cd .. || exit 1

# XCB
[ ! -d xcb ] && mkdir xcb
cd xcb

say "cxb:pthread-stubs" && [ ! -d pthread-stubs ] && git clone git://anongit.freedesktop.org/xcb/pthread-stubs
cd pthread-stubs && git pull && ./autogen.sh --prefix=$WLD && make && sudo -E make install && cd .. || exit 1

cd ..

# MESA
[ ! -d mesa ] && mkdir mesa
cd mesa

say "mesa:drm" && [ ! -d drm ] && git clone git://anongit.freedesktop.org/git/mesa/drm
cd drm && git pull && ./autogen.sh --prefix=$WLD --enable-nouveau-experimental-api && make && sudo -E make install && cd .. || exit 1

say "mesa:macros" && [ ! -d macros ] && git clone git://anongit.freedesktop.org/git/xorg/util/macros
cd macros && git pull && ./autogen.sh --prefix=$WLD && make && sudo -E make install && cd .. || exit 1

say "mesa:glproto" && [ ! -d glproto ] && git clone git://anongit.freedesktop.org/xorg/proto/glproto
cd macros && git pull && ./autogen.sh --prefix=$WLD && make && sudo -E make install && cd .. || exit 1

say "mesa:dri2proto" && [ ! -d dri2proto ] && git clone git://anongit.freedesktop.org/xorg/proto/dri2proto
cd macros && git pull && ./autogen.sh --prefix=$WLD && make && sudo -E make install && cd .. || exit 1

say "mesa:mesa" && [ ! -d mesa ] && git clone git://anongit.freedesktop.org/mesa/mesa
cd mesa && git pull && ./autogen.sh --prefix=$WLD --enable-gles2 --disable-gallium-egl \
    --with-egl-platforms=x11,wayland,drm --enable-gbm --enable-shared-glapi && make && sudo -E make install && cd .. || exit 1

cd ..

# XORG
[ ! -d xorg ] && mkdir xorg
cd xorg

say "xorg:macros" && [ ! -d macros ] && git clone git://anongit.freedesktop.org/xorg/util/macros
cd macros && git pull &&./autogen.sh --prefix=$WLD && make && sudo -E make install && cd .. || exit 1

say "xorg:xproto" && [ ! -d xproto ] && git clone git://anongit.freedesktop.org/xorg/proto/xproto
cd xproto && git pull && ./autogen.sh --prefix=$WLD && make && sudo -E make install && cd .. || exit 1

say "xorg:kbproto" && [ ! -d kbproto ] && git clone git://anongit.freedesktop.org/xorg/proto/kbproto
cd kbproto && git pull && ./autogen.sh --prefix=$WLD && make && sudo -E make install && cd .. || exit 1

say "xorg:libX11" && [ ! -d libX11 ] && git clone git://anongit.freedesktop.org/xorg/lib/libX11
cd libX11 && git pull && ./autogen.sh --prefix=$WLD --enable-specs=false && make && sudo -E make install && cd .. || exit 1

say "xorg:libxkbcommon" && [ ! -d libxkbcommon ] && git clone git://people.freedesktop.org/xorg/lib/libxkbcommon.git libxkbcommon
cd libxkbcommon && git pull &&  ./autogen.sh --prefix=$WLD --with-xkb-config-root=/usr/share/X11/xkb && make && sudo -E make install && cd .. || exit 1

say "xorg:pixman" && [ ! -d pixman ] && git clone git://anongit.freedesktop.org/pixman
cd pixman && git pull && ./autogen.sh --prefix=$WLD && make && sudo -E make install && cd .. || exit 1

say "xorg:cairo" && [ ! -d cairo ] && git clone git://anongit.freedesktop.org/cairo
cd cairo && git pull && ./autogen.sh --prefix=$WLD --enable-gl --enable-xcb && make && sudo -E make install && cd .. || exit 1

cd ..

# WAYLAND-DEMOS
say "wayland-demos" && [ ! -d wayland-demos ] && git clone git://anongit.freedesktop.org/wayland/wayland-demos
cd wayland-demos && git pull && ./autogen.sh --prefix=$WLD && make && sudo -E make install && cd .. || exit 1

say "DONE"

