#! /bin/bash

SUDO_PASSWD=""

EFL_VER=1.7.6
E_VER=0.17.2
BASE_URL="http://download.enlightenment.fr/releases"
DBUS_SRV_PATH="/usr/share/dbus-1/services"

unset LANG
export CFLAGS="-O2 -march=native -ffast-math"
export CC="ccache gcc"
alias make='make -j4'

PREFIX=/opt/efl-release
export PATH="$PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$PREFIX/lib"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"

EFL_FLAGS="--disable-doc --disable-static"
E_FLAGS="--enable-pam --disable-device-hal --enable-device-udev --enable-mount-udisks --enable-mount-eeze --enable-elementary --enable-emotion --enable-enotify"
E_FLAGS+=" --sysconfdir=/etc"

EFL_PKGS="eina eet evas ecore eio embryo edje efreet e_dbus eeze emotion ethumb elementary"

function e_get() {
    echo "fetch archives"
    for pkg in $EFL_PKGS; do
        arch=${pkg}-${EFL_VER}.tar.bz2
        echo "  - $arch"
        [ -f $arch ] || curl -L "$BASE_URL/$arch" -o $arch || exit 1
    done
    e_arch=enlightenment-${E_VER}.tar.bz2
    echo "  - $e_arch"
    [ -f $e_arch ] || curl -L "$BASE_URL/$e_arch" -o $e_arch || exit 1
}

function e_extract() {
    echo "extract archives"
    for pkg in $EFL_PKGS; do
        echo "  - $arch"
        [ -d $pkg-${EFL_VER} ] && rm -rf $pkg-${EFL_VER}
        arch=${pkg}-${EFL_VER}.tar.bz2
        tar -xjf $arch || exit 1
    done
    echo "  - $e_arch"
    [ -d enlightenment-${E_VER} ] && rm -rf enlightenment-${E_VER}
    e_arch=enlightenment-${E_VER}.tar.bz2
    tar -xjf $e_arch || exit 1
}

function e_build() {
    echo "build and install"
    for pkg in $EFL_PKGS; do
        echo "  - $pkg"
        cd $pkg-${EFL_VER} || exit 1
        ./autogen.sh --prefix=$PREFIX $EFL_FLAGS
        if [ $? -ne 0 ]; then
            echo " - FIX configure.ac" && sed -i 's/AM_PROG_CC_STDC/AC_PROG_CC/g' configure.ac && sed -i 's/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/g' configure.ac || exit 1
            ./autogen.sh --prefix=$PREFIX $EFL_FLAGS || exit 1
        fi
        make && echo "$PASSWD" | sudo -S make install && cd .. || exit 1
    done
    echo "  - $e_arch"
    cd enlightenment-${E_VER} && ./configure --prefix=$PREFIX --libexecdir=$PREFIX/lib/enlightenment $E_FLAGS && make && echo "$PASSWD" | sudo -S make install && cd .. || exit 1
    cd $DBUS_SRV_PATH || exit 1
    for $srv in $PREFIX/share/dbus-1/services/*; do
       echo "$PASSWD" | sudo -S ln -s $srv
    done

}

function get_sudopwd() {
    sudo_test=/tmp/_sudo.test
    echo -n "enter sudo-password: " && stty -echo && read SUDO_PASSWD && stty echo || exit 1
    [ -e $sudo_test ] && rm -f $sudo_test
    echo "$SUDO_PASSWD" | sudo -S touch $sudo_test
    if [ ! -e $sudo_test ]; then
        echo "cmdline provided sudo password failed!"
        exit 1
    fi
}

get_sudopwd
e_get
e_extract
e_build
