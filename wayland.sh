#!/bin/bash

# hbased on ttp://wayland.freedesktop.org/building.html

WLD=/opt/wayland
LD_LIBRARY_PATH=$WLD/lib
PKG_CONFIG_PATH=$WLD/lib/pkgconfig/:$WLD/share/pkgconfig/
ACLOCAL="aclocal -I $WLD/share/aclocal"
C_INCLUDE_PATH=$WLD/include
LIBRARY_PATH=$WLD/lib
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1

#export WLD LD_LIBRARY_PATH PKG_CONFIG_PATH ACLOCAL C_INCLUDE_PATH LIBRARY_PATH PKG_CONFIG_ALLOW_SYSTEM_CFLAGS

BUILD_DIR=${BUILD_DIR:-~/local}
FORCE_AUTOGEN=0
FORCE_DISTCLEAN=0
SUDO_PASSWD=""
for arg in $@; do
    option=`echo "'$arg'" | cut -d'=' -f1 | tr -d "'"`
    value=`echo "'$arg'" | cut -d'=' -f2- | tr -d "'"`
    case $option in
        "-f")   FORCE_AUTOGEN=1;;
        "-c")   FORCE_DISTCLEAN=1;;
        "-s")   SUDO_PASSWD=$value;;
    esac
done

RESET="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"

function say () { echo -e "$GREEN$1$RESET"; }

function abort () { echo -e "${RED}ABORT${RESET} $1" && exit 1; }

function error () { echo -e "${RED}FAILURE${RESET} $1"; }

sudo -K
TMP=/tmp/sudo.test
[ -e "$TMP" ] && rm -f "$TMP"
echo "$SUDO_PASSWD" | sudo -S touch "$TMP" &>/dev/null
if [ ! -e "$TMP" ]; then
    abort "cmdline provided sudo password failed!"
else
    echo "$SUDO_PASSWD" | sudo -S rm -f "$TMP"
fi
echo

function build () {
    if [ $FORCE_AUTOGEN -eq 1 -o ! -e Makefile ]; then
        say " * autogen.sh --prefix=$WLD $my_configure_opts" && ./autogen.sh --prefix=$WLD $my_configure_opts
    fi
    if [ $FORCE_DISTCLEAN -eq 1 ]; then
        say " * make distclean" && make distclean >/dev/null
    fi
    tmp=/tmp/$my_dir.build
    say " * make" && make >$tmp && say " * install" && echo "$SUDO_PASSWD" | sudo -S -E make install
}

function update () {
    SHA_PREV=$(git log --pretty="format:%H" HEAD~1..)
    say " * pull" && git pull || return 1
    SHA_HEAD=$(git log --pretty="format:%H" HEAD~1..)
    if [ $FORCE_AUTOGEN -eq 1 -o $FORCE_DISTCLEAN -eq 1 ]; then
        build
    else
        [ "$SHA_PREV" = "$SHA_HEAD" ] && return 0
        build
    fi
}

function do_your_job () {
    if [ -d "$my_dir" ]; then
        cd "$my_dir" && update && cd .. || error
    else
        say " * clone $my_src" && git clone "$my_src" "$my_dir" && cd "$my_dir" && build && cd .. || error
    fi
}

cd $BUILD_DIR || exit 1

# WAYLAND
say "wayland"
my_dir=wayland
my_src=git://anongit.freedesktop.org/wayland/wayland
my_configure_opts=
do_your_job

# WESTON
say "weston"
my_dir=weston
my_src=git://anongit.freedesktop.org/wayland/weston
my_configure_opts=
do_your_job

# WAYLAND-DEMOS
say "wayland-demos"
my_dir=wayland-demos
my_src=git://anongit.freedesktop.org/wayland/wayland-demos
my_configure_opts=
do_your_job

say "DONE"

