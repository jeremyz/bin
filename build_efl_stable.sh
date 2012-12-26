#! /bin/bash

EFL_VER=1.7.4
E_VER=0.17.0
PREFIX=/opt/efl
OPTIONS="--disable-doc"
SUDO_PASSWD=""
BASE_URL="http://download.enlightenment.fr/releases"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"

EFL_PKGS="eina eet evas ecore eio embryo edje efreet e_dbus eeze emotion ethumb elementary"

function e_get() {
    echo "fetch archives"
    for pkg in $EFL_PKGS; do
        arch=${pkg}-${EFL_VER}.tar.bz2
        echo "  - $arch"
        [ -f $arch ] || curl "$BASE_URL/$arch" -o $arch || exit 1
    done
    e_arch=enlightenment-${E_VER}.tar.bz2
    echo "  - $e_arch"
    [ -f $e_arch ] || curl "$BASE_URL/$e_arch" -o $e_arch || exit 1
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
        cd $pkg-${EFL_VER} && ./autogen.sh --prefix=$PREFIX $OPTIONS && make && echo "$PASSWD" | sudo -S make install && cd .. || exit 1
    done
    echo "  - $e_arch"
    cd enlightenment-${E_VER} && ./configure --prefix=$PREFIX $OPTIONS && make && echo "$PASSWD" | sudo -S make install && cd .. || exit 1
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
