#!/usr/bin/env bash

#############################################################################
# This script is a result of the ideas from the people of different e       #
# channels at irc.freenode.net                                              #
# It will checkout the repository and compile e17.                          #
#                                                                           #
# License: BSD licence                                                      #
# Get the latest version at http://omicron.homeip.net/projects/#easy_e17.sh #
# Coded by Brian 'morlenxus' Miculcy (morlenxus@gmx.net)                    #
#                                                                           #
last_changes="2010-10-12"                                                   #
version="1.4.0"                                                             #
#############################################################################


# Internal variables, run easy_e17.sh --help to get a cleaner way!
tmp_path="/tmp/easy_e17"
logs_path="$tmp_path/install_logs"
status_path="$tmp_path/status"
src_cache_path="$tmp_path/src_cache"
src_path="$HOME/e17_src"

src_url="http://svn.enlightenment.org/svn/e/trunk"
src_rev="HEAD"
conf_files="/etc/easy_e17.conf $HOME/.easy_e17.conf $PWD/.easy_e17.conf"

efl_basic="eina eet evas ecore efreet eio eeze e_dbus embryo edje"
efl_extra="imlib2 emotion ethumb libeweather elementary enlil ensure libast python-evas python-ecore python-e_dbus python-edje python-ethumb python-emotion python-elementary shellementary azy"
bin_basic="exchange e"
bin_extra="calculator converter phonebook sticky-notes e_phys edje_viewer editje elsa emote empower enjoy enki envision ephoto Eterm eve expedite exquisite eyelight rage elmdentica"
bin_games="eblock e_cho econcentration eskiss e-type minesweeper ninestime"
e_modules_bin="emprint exalt"
e_modules_extra="mpdule exebuf cpu mem slideshow wlan elfe everything-pidgin execwatch calendar notification efm_nav snow drawer everything-skel engage everything-mpris diskio exalt-client everything-wallpaper everything-aspell screenshot rain comp-scale efm_path places eweather deskshow winlist-ng weather mail everything-tracker eooorg empris xkbswitch penguins moon iiirk alarm photo skel language news taskbar everything-places tclock tiling flame itask forecasts efm_pathbar everything-websearch winselector quickaccess uptime net"

packages_basic="$efl_basic $bin_basic"
packages_half="$efl_basic $bin_basic $e_modules_bin $e_modules_extra"
packages_full="$efl_basic $bin_basic $e_modules_bin $e_modules_extra $efl_extra $bin_extra $bin_games"
packages=$packages_basic    # default

cmd_svn_test="svn info"
cmd_svn_list="svn list -r"
cmd_svn_checkout="svn checkout -r "
cmd_svn_update_conflicts_solve="svn update --accept theirs-full -r"
cmd_svn_update_conflicts_ask="svn update -r"
src_mode="packages"
ignore_dirs="devs DOCS E16 EXAMPLES TEST THEMES web"
autogen_args=""        # evas:--enable-gl-x11
linux_distri=""        # if your distribution is wrongly detected, define it here
nice_level=0        # nice level (19 == low, -20 == high)
os=$(uname)            # operating system
threads=2            # make -j <threads>

animation="star"
online_source="http://omicron.homeip.net/projects/easy_e17/easy_e17.sh"    # URL of latest stable release


# VISUAL #############################################################################

function set_title ()
{
    if [ "$1" ]; then message="- $1"; fi
    if [ "$DISPLAY" ]; then
        case "$TERM" in
            xterm*|rxvt*|Eterm|eterm|Aterm|aterm)
                echo -ne "\033]0;Easy_e17.sh $message\007"
                ;;
        esac
    fi
}

function set_notification ()
{
    if [ -z "$DISPLAY" ] || [ "$notification_disabled" ]; then return; fi
    notifier="$install_path/bin/e-notify-send"
    urgency=$1
    text=$2
    if [ -x "$notifier" ]; then
        $notifier -u "$urgency" -t 5000 -i "$install_path/share/enlightenment/data/images/enlightenment.png" \
                  -n "easy_e17.sh" "easy_e17.sh" "$text" &>/dev/null
    fi
}

function wrong () {
    header
    if [ "$1" ]; then
        echo -e "\033[1m-------------------------------\033[7m Bad script argument \033[0m\033[1m----------------------------\033[0m"
        echo -e "  \033[1m$1\033[0m"
    else
        help
        exit 0
    fi
    echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
    echo
    echo
    exit 1
}

function open_header ()
{
    l=${#1}
    set_title $1
    padding=""
    for (( i=$((46-l)); i > 0; i-- )) do
        padding="$padding-"
    done
    echo -e "\n\033[1m-------------------------------\033[7m $1 \033[0m\033[1m-$padding\033[0m"
}

function header ()
{
    clear
    echo -e "\033[1m-------------------------------\033[7m Easy_e17.sh $version \033[0m\033[1m------------------------------\033[0m"
    echo -e "\033[1m  Developers:\033[0m      Brian 'morlenxus' Miculcy"
    echo -e "                   David 'onefang' Seikel"
    echo -e "\033[1m  Contributors:\033[0m    Tim 'amon' Zebulla"
    echo -e "                   Daniel G. '_ke' Siegel"
    echo -e "                   Stefan 'slax' Langner"
    echo -e "                   Massimiliano 'Massi' Calamelli"
    echo -e "                   Thomas 'thomasg' Gstaedtner"
    echo -e "                   Roberto 'rex' Sigalotti"
    echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
    echo -e "\033[1m  Updates:\033[0m         http://omicron.homeip.net/projects/#easy_e17.sh"
    echo -e "\033[1m  Support:\033[0m         #e.de (irc.freenode.net)"
    echo -e "                   morlenxus@gmx.net"
    echo -e "\033[1m  Patches:\033[0m         Generally accepted, please contact me!"
    echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
    echo
    echo
    echo -e "\033[1m-----------------------------\033[7m Current Configuration \033[0m\033[1m----------------------------\033[0m"
    echo "  Config files:    $conf_files"
    echo "  Install path:    $install_path"
    echo "  Source path:     $src_path"
    echo "  Source url:      $src_url (Revision: $src_rev)"
    echo "  Source mode:     $src_mode"
    echo "  Logs path:       $logs_path"
    if [ "$linux_distri" ]; then
        echo "  OS:              $os (Distribution: $linux_distri)"
    else
        echo "  OS:              $os"
    fi
    echo
    if [ "$only" ]; then echo "  Only:            $only"; fi
    if [ "$skip" ]; then echo "  Skipping:        $skip"; fi
    echo "  Packages:       $effective_packages"
    echo
    if [ -z "$action" ]; then action="MISSING!"; fi
    echo "  Script action:   $action"
    echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
    echo
}

function help ()
{
    if [ "$os" == "not supported" ]; then
        echo -e "\033[1m-------------------------------\033[7m Not supported OS \033[0m\033[1m------------------------------\033[0m"
        echo "  Your operating system '$(uname)' is not supported by this script."
        echo "  If possible please provide a patch."
    elif [ -z "$fullhelp" ]; then
        echo -e "\033[1m-----------------\033[7m Short help 'easy_e17.sh <ACTION> <OPTIONS...>' \033[0m\033[1m---------------\033[0m"
        echo "  -i, --install            = ACTION: install efl+e17"
        echo "  -u, --update             = ACTION: update your installed software"
        echo "      --packagelist=<list> = software package list:"
        echo "                             - basic: only e17 (default)"
        echo "                             - half:  only e17 and extra modules"
        echo "                             - full:  simply everything"
        echo "      --help               = full help"
    else
        echo -e "\033[1m-----------------\033[7m Full help 'easy_e17.sh <ACTION> <OPTIONS...>' \033[0m\033[1m----------------\033[0m"
        echo -e "  \033[1mACTION:\033[0m"
        echo "  -i, --install                       = ACTION: install efl+e17"
        echo "  -u, --update                        = ACTION: update installed software"
        echo "      --only=<name1>,<name2>,...      = ACTION: install ONLY named libs/apps"
        echo "      --packagelist=<list>            = software package list:"
        echo "                                        - basic: only e17 (default)"
        echo "                                        - half:  only e17 and extra modules"
        echo "                                        - full:  simply everything"
        echo
        echo "      --srcupdate                     = update only the sources"
        echo "  -v, --check-script-version          = check for a newer release of easy_e17"
        echo "      --help                          = this help"
        echo
        echo -e "  \033[1mOPTIONS:\033[0m"
        echo "      --conf=<file>                   = use an alternate configuration file"
        echo "      --instpath=<path>               = change the default install path"
        echo "      --srcpath=<path>                = change the default source path"
        echo "      --srcurl=<url>                  = change the default source url"
        echo "      --srcmode=<packages/full>       = checkout only required package source"
        echo "                                        or simply everthing (huge)"
        echo "      --srcrev=<revision>             = set the default source revision"
        echo "      --asuser                        = do everything as the user, not as root"
        echo "      --no-sudopwd                    = sudo don't need a password..."
        echo "  -c, --clean                         = clean the sources before building"
        echo "                                        (more --cleans means more cleaning, up"
        echo "                                        to a maximum of three, which will"
        echo "                                        uninstall e17)"
        echo "  -s, --skip-srcupdate                = don't update sources"
        echo "  -a, --ask-on-src-conflicts          = ask what to do with a conflicting"
        echo "                                        source file"
        echo "      --skip=<name1>,<name2>,...      = this will skip installing the named"
        echo "                                        libs/apps"
        echo "  -d, --docs                          = generate programmers documentation"
        echo "      --postscript=<name>             = full path to a script to run as root"
        echo "                                        after installation"
        echo "  -e, --skip-errors                   = continue compiling even if there is"
        echo "                                        an error"
        echo "  -w, --wait                          = don't exit the script after finishing,"
        echo "                                        this allows 'xterm -e ./easy_e17.sh -i'"
        echo "                                        without closing the xterm"
        echo "  -n  --disable-notification          = disable the osd notification"
        echo "  -k, --keep                          = don't delete the temporary dir"
        echo
        echo "  -l, --low                           = use lowest nice level (19, slowest,"
        echo "                                        takes more time to compile, select"
        echo "                                        this if you need to work on the pc"
        echo "                                        while compiling)"
        echo "      --normal                        = default nice level ($nice_level),"
        echo "                                        will be automatically used"
        echo "  -h, --high                          = use highest nice level (-20, fastest,"
        echo "                                        slows down the pc)"
        echo "      --cache                         = Use a common configure cache and"
        echo "                                        ccache if available"
        echo "      --threads=<int>                 = 'make' can use threads, recommended on"
        echo "                                        smp systems (default: 2 threads)"
        echo "      --autogen_args=<n1>:<o1>+<o2>,. = pass some options to autogen:"
        echo "                                        <name1>:<opt1>+<opt2>,<name2>:<opt1>+..."
        echo "      --cflags=<flag1>,<flag2>,...    = pass cflags to the gcc"
        echo "      --ldflags=<flag1>,<flag2>,...   = pass ldflags to the gcc"
        echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
        echo
        echo -e "\033[1m----------------------\033[7m Configurationfile '~/.easy_e17.conf' \033[0m\033[1m--------------------\033[0m"
        echo "  Just create this file and save your favourite arguments."
        echo "  Example: If you use a diffent source path, add this line:"
        echo "           --srcpath=$HOME/enlightenment/e17_src"
    fi
}


# INIT #############################################################################

function define_os_vars ()
{
    case $os in
        Darwin)
            install_path="/opt/e17"
            # ldconfig="/sbin/ldconfig" # FIXME: Someone with Darwin seeing this should check availability!
            make="make"
            export ACLOCAL_FLAGS="$ACLOCAL_FLAGS -I /opt/local/share/aclocal"
            export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/local/lib/pkgconfig"
            export CPPFLAGS="$CPPFLAGS -I/opt/local/include"
            export LDFLAGS="$LDFLAGS -Wl,-L/opt/local/lib"
            ;;
        FreeBSD)
            install_path="/usr/local/e17"
            ldconfig="/sbin/ldconfig"
            make="gmake"
            export ACLOCAL_FLAGS=" -I /usr/local/share/aclocal"
            export CPPFLAGS="$CPPFLAGS -I/usr/local/include -I/usr/X11R6/include -I$install_path/include"
            export CFLAGS="$CFLAGS -lintl -liconv -L/usr/local/lib -L/usr/X11R6/lib -L$install_path/lib -I/usr/local/include -I/usr/X11R6/include -I$install_path/include" # FIXME: Someone with FreeBSD seeing this should check if includes are needed here!
            export LDFLAGS="$LDFLAGS -lexecinfo"
            ;;
        NetBSD)
            install_path="/usr/pkg/e17"
            ldconfig="config"
            make="make"
            export CFLAGS+="$CFLAGS -I/usr/pkg/include -I/usr/X11R7/include"
            export CPPFLAGS+="$CPPFLAGS -I/usr/pkg/include -I/usr/X11R7/include"
            export LDFLAGS+="$LDFLAGS -L/usr/pkg/include -L/usr/pkg/lib -L/usr/X11R7/lib"
            ;;
        Linux)
            install_path="/opt/e17"
            ldconfig="/sbin/ldconfig"
            make="make"
            if [ -z "$linux_distri" ]; then
                if [ -e "/etc/debian_version" ]; then linux_distri="debian"; fi
                if [ -e "/etc/gentoo-release" ]; then linux_distri="gentoo"; fi
                if [ -e "/etc/redhat-release" ]; then linux_distri="redhat"; fi
                if [ -e "/etc/SuSE-release" ];   then linux_distri="suse";     fi
            fi
            ;;
        SunOS)
            install_path="/opt/e17"
            ldconfig="$(which crle) -u"    # there is no command like ldconfig on solaris! "crle" does nearly the same.
            make="make"
            ;;
        *)
            os="not supported"
            set_title
            wrong
            ;;
    esac
}

function read_config_files ()
{
    # add alternate config files
    for arg in $my_args; do
        option=`echo "'$arg'" | cut -d'=' -f1 | tr -d "'"`
        value=`echo "'$arg'" | cut -d'=' -f2- | tr -d "'"`
        if [ "$value" == "$option" ]; then value=""; fi
        if [ "$option" == "--conf" -a -e "$value" ]; then conf_files="$conf_files $value"; fi
    done
    # remove duplicated and no existing files
    tmp=""
    for conf_file in $conf_files; do
        if [ -e "$conf_file" ]; then
            exists=0
            for tmp_file in $tmp; do
                if [ "$conf_file" == "$tmp_file" ]; then
                    exists=1
                    break;
                fi
            done
            if [ $exists -eq 0 ]; then tmp="$tmp $conf_file"; fi
        fi
    done
    conf_files=$tmp
    conf_options=""
    # read files
    for file in $conf_files; do
        for option in `cat "$file"`; do
            conf_options="$conf_options $option"
        done
    done
    my_args="$conf_options $my_args"
}

function parse_args ()
{
    # check options
    for arg in $my_args
    do
        option=`echo "'$arg'" | cut -d'=' -f1 | tr -d "'"`
        value=`echo "'$arg'" | cut -d'=' -f2- | tr -d "'"`
        if [ "$value" == "$option" ]; then value=""; fi
        # $action can't be set twice
        if [ "$action" ]; then
            if [ "$option" == "-i" ] ||
               [ "$option" == "--install" ] ||
               [ "$option" == "-u" ] ||
               [ "$option" == "--update" ] ||
               [ "$option" == "--only" ] ||
               [ "$option" == "--srcupdate" ] ||
               [ "$option" == "-v" ] ||
               [ "$option" == "--check-script-version" ]; then
                wrong "Only one action allowed! (currently using '--$action' and '$option')"
            fi
        fi
        case "$option" in
            -i|--install)                   action="install" ;;
            -u|--update)                    action="update" ;;
            --packagelist)
                case $value in
                    "half")                 packages="$packages_half" ;;
                    "full")                 packages="$packages_full" ;;
                    *)                      packages="$packages_basic" ;;
                esac
                ;;
            --conf)                    ;;
            --only)
                if [ -z "$value" ]; then
                    wrong "Missing value for argument '$option'!"
                fi
                action="only"
                only="`echo "$value" | tr -s '\,' '\ '` $only"
                ;;
            -v|--check-script-version)      action="script" ;;
            --srcupdate)
                action="srcupdate"
                skip="$packages"
                ;;
            --instpath)                     install_path="$value" ;;
            --srcpath)                      src_path="$value" ;;
            --srcurl)                       src_url="$value" ;;
            --srcmode)
                case $value in
                    "packages")             src_mode="packages" ;;
                    "full")                 src_mode="full" ;;
                    *)                      src_mode="packages" ;;
                esac
                ;;
            --srcrev)
                if [ -z "$value" ]; then
                    wrong "Missing value for argument '$option'!"
                fi
                src_rev="$value"
                ;;
            --asuser)                       asuser=1 ;;
            --no-sudopwd)                   no_sudopwd=1 ;;
            -c|--clean)                     clean=$(($clean + 1))    ;;
            -d|--docs)                      gen_docs=1 ;;
            --postscript)                   easy_e17_post_script="$value" ;;
            -s|--skip-srcupdate)            skip_srcupdate=1 ;;
            -a|--ask-on-src-conflicts)      ask_on_src_conflicts=1 ;;
            --skip)
                if [ -z "$value" ]; then
                    wrong "Missing value for argument '$option'!"
                fi
                skip="`echo "$value" | tr -s '\,' '\ '` $skip"
                ;;
            -e|--skip-errors)               skip_errors=1 ;;
            -w|--wait)                      wait=1 ;;
            -n|--disable-notification)      notification_disabled=1 ;;
            -k|--keep)                      keep=1 ;;

            -l|--low)                       nice_level=19 ;;
            --normal) ;;
            -h|--high)                      nice_level=-20 ;;
            --cache)
                accache=" --cache-file=$tmp_path/easy_e17.cache"
                ccache=`whereis ccache`
                if [ ! "$ccache" = "ccache:" ]; then
                    export CC="ccache gcc"
                fi
                ;;
            --threads)
                if [ -z "$value" ] || ! expr "$value" : "[0-9]*$" >/dev/null || [ "$value" -lt 1 ]; then
                    wrong "Missing value for argument '$option'!"
                fi
                threads=$value
                ;;
            --autogen_args)
                if [ -z "$value" ]; then
                    wrong "Missing value for argument '$option'!"
                fi
                autogen_args="$value"
                ;;
            --cflags)
                if [ -z "$value" ]; then
                    wrong "Missing value for argument '$option'!"
                fi
                CFLAGS="$CFLAGS `echo "$value" | tr -s '\,' '\ '`"
                ;;
            --ldflags)
                if [ -z "$value" ]; then
                    wrong "Missing value for argument '$option'!"
                fi
                LDFLAGS="$LDFLAGS `echo "$value" | tr -s '\,' '\ '`"
                ;;
            --help)
                fullhelp=1
                wrong
                ;;
            *)
                wrong "Unknown argument '$option'!"
                ;;
        esac
    done
}


function build_package_list ()
{
    effective_packages=""
    if [ "$only" ]; then
        pkgs=$only
    else
        pkgs=$packages
    fi
    for pkg in $pkgs; do
        found=0
        for not in $skip; do
            if [ "$not" == "$pkg" ]; then
                found=1
                break
            fi
        done
        [ $found -eq 0 ] && effective_packages="$effective_packages $pkg"
    done
}

# SETUP #############################################################################

function check_script_version ()
{
    echo -e "\033[1m------------------------------\033[7m Check script version \033[0m\033[1m----------------------------\033[0m"
    echo "- local version .............. $version"
    echo -n "- downloading script ......... "
    remote_version=`wget $online_source -q -U "easy_e17.sh/$version" -O - | grep -m 2 -o [0-9]\.[0-9]\.[0-9] | sort -n | head -n 1`
    if [ "$remote_version" ]; then
        echo "ok"
        echo "- remote version ............. $remote_version"
        remote_ver=`echo "$remote_version" | tr -d '.'`
        local_ver=`echo "$version" | tr -d '.'`
        echo
        echo -n "- update available ........... "
        if [ $remote_ver -gt $local_ver ]; then
                echo -e "\033[1mYES!\033[0m"
        else    echo "no"; fi
    else
        echo -e "\033[1mERROR!\033[0m"
    fi
    echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
    echo
    exit 0
}

function check_commands ()
{
    max=15
    for dep in $1; do
        cnt=${#dep}
        echo -n "- '$dep' available "
        while [ ! $cnt = $max ]; do
            echo -n "."
            cnt=$(($cnt+1))
        done
        echo -n " "
        if [ `type $dep &>/dev/null; echo $?` -ne 0 ]; then
            echo -e "\033[1mNOT INSTALLED!\033[0m"
            error "Command missing!"
        else
            echo "ok"
        fi
    done
}

function check_build_user ()
{
    echo -n "- build-user ................. "
    if [ "$LOGNAME" == "root" ]; then
        echo "root"
        mode="root"
        return
    fi
    if [ "$asuser" ]; then
        echo "$LOGNAME (as user)"
        mode="user"
        return
    fi
    echo "$LOGNAME (non-root)"
    echo -n "- sudo available ............. "
    sudotest=`type sudo &>/dev/null ; echo $?`
    if [ "$sudotest" == 0 ]; then
        if [ "$no_sudopwd" == 1 ]; then
            echo "ok"
        else
            sudo -K
            if [ -e "$tmp_path/sudo.test" ]; then
                rm -f "$tmp_path/sudo.test"
            fi
            while [ -z "$sudopwd" ]; do
                echo -n "enter sudo-password: "
                stty -echo
                read sudopwd
                stty echo
                # password check
                echo "$sudopwd" | sudo -S touch "$tmp_path/sudo.test" &>/dev/null
                if [ ! -e "$tmp_path/sudo.test" ]; then
                    sudopwd=""
                fi
            done
            rm -f "$tmp_path/sudo.test"
        fi
        echo
        mode="sudo"
    else
        error "You're not root and sudo isn't available. Please run this script as root!"
    fi
}

function set_build_env ()
{
    echo -n "- setting env variables ...... "
    export PATH="$install_path/bin:$PATH"
    export ACLOCAL_FLAGS="-I $install_path/share/aclocal $ACLOCAL_FLAGS"
    export LD_LIBRARY_PATH="$install_path/lib:$LD_LIBRARY_PATH"
    export PKG_CONFIG_PATH="$install_path/lib/pkgconfig:$PKG_CONFIG_PATH"
    export CPPFLAGS="$CPPFLAGS -I$install_path/include"
    export LDFLAGS="$LDFLAGS -L$install_path/lib"
    export CFLAGS="$CFLAGS"
    export PYTHONPATH=`python -c "import distutils.sysconfig; print distutils.sysconfig.get_python_lib(prefix='$install_path')" 2>/dev/null`
    export PYTHONINCLUDE=`python -c "import distutils.sysconfig; print distutils.sysconfig.get_python_inc(prefix='$install_path')" 2>/dev/null`
    echo "ok"
}

function check_ld_path ()
{
    echo -n "- checking lib-path in ld .... "
    case $os in
        FreeBSD) ;; # TODO: placeholder
        SunOS)     ;; # TODO: need more testing of adding libraries on different solaris versions. atm this is not working
        Linux)
            libpath="`grep -r -l -i -m 1 $install_path/lib /etc/ld.so.conf*`"
            if [ -z "$libpath" ]; then
                case $linux_distri in
                    gentoo)
                        e17ldcfg="/etc/env.d/40e17paths"
                        echo -e "PATH=$install_path/bin\nROOTPATH=$install_path/sbin:$install_path/bin\nLDPATH=$install_path/lib\nPKG_CONFIG_PATH=$install_path/lib/pkgconfig" > $e17ldcfg
                        env-update &> /dev/null
                        echo "ok (path has been added to $e17ldcfg)";
                        ;;

                    *)
                        if [ "`grep -l 'include /etc/ld.so.conf.d/' /etc/ld.so.conf`" ]; then
                            e17ldcfg="/etc/ld.so.conf.d/e17.conf"
                        else
                            e17ldcfg="/etc/ld.so.conf";
                            cp $e17ldcfg $tmp_path;
                        fi

                        case "$mode" in
                            "user") ;;
                            "root")    echo "$install_path/lib" >>$e17ldcfg ;;
                            "sudo")
                                echo "$install_path/lib" >> $tmp_path/`basename $e17ldcfg`
                                echo "$sudopwd" | sudo -S mv -f $tmp_path/`basename $e17ldcfg` $e17ldcfg
                                ;;
                        esac
                        if [ "$asuser" ]; then
                                echo "skipped (running as user)";
                        else    echo "ok (path has been added to $e17ldcfg)"; fi
                        ;;
                esac
            else
                echo "ok ($libpath)";
            fi
            ;;
    esac
}

function mk_dest_dirs ()
{
    echo -n "- creating destination dirs .. "
    case "$mode" in
        user|root)    mkdir -p "$install_path/share/aclocal" ;;
        sudo)        echo "$sudopwd" | sudo -S mkdir -p "$install_path/share/aclocal" ;;
    esac
    # PYTHON BINDING FIXES
    if [ "$PYTHONPATH" ]; then
        case "$mode" in
            user|root)    mkdir -p "$PYTHONPATH" ;;
            sudo)        echo "$sudopwd" | sudo -S mkdir -p "$PYTHONPATH" ;;
        esac
    fi
    if [ "$PYTHONINCLUDE" ]; then
        case "$mode" in
            user|root)    mkdir -p "$PYTHONINCLUDE" ;;
            sudo)        echo "$sudopwd" | sudo -S mkdir -p "$PYTHONINCLUDE" ;;
        esac
    fi
    echo "ok"
}


# SVN #############################################################################

function backoff_loop
{
    src_cmd=$1
    backoff=5
    attempt=1
    max_attempt=5
    while [ 1 ]; do
        $src_cmd | tee -a "$tmp_path/source_update.log"
        if [ "${PIPESTATUS[0]}" -gt 0 ]; then
            attempt=$(($attempt + 1))
            set_title "Source update failed, trying again in $backoff seconds..."
            for (( i=$(($backoff*$attempt)); i > 0; i-- )) do
                echo -n -e "\rFAILED! Next attempt $attempt in \033[1m$i\033[0m seconds"
                sleep 1
            done
            echo -n -e "\r                                                            \r"
        else
            break
        fi
        if [ $attempt == $max_attempt ]; then
            echo -e "\rFAILED! To many attempts ($attempt)\033[0m" && return
        fi
    done
}

function find_svn_path ()
{
    package=$1
    subdir=$2
    depth=$3
    cachefile=$src_cache_path/cache_`echo "$subdir" | tr '/' '_'`
    if [ $depth -gt 4 ]; then return; fi
    if [ ! -e "$cachefile" ]; then
        # TODO use backoff_loop
        $cmd_svn_list $src_rev "$src_url/$subdir" | egrep "/$" >$cachefile
    fi
    contents=`cat $cachefile`
    for dir in $contents; do
        if [ "$dir" == "$package/" ]; then
            echo "$subdir/$dir"
            return
        fi
    done
    for dir in $contents; do
        found=0
        for pkg in $packages; do
            if [ "$dir" == "$pkg/" ]; then found=1; fi
        done
        if [ $found == 1 ]; then continue; fi
        for idir in $ignore_dirs; do
            if [ "$dir" == "$idir/" ]; then found=1; fi
        done
        if [ $found == 1 ]; then continue; fi
        svn_path=`find_svn_path $package "$subdir/$dir" $(($depth+1))`
        if [ "$svn_path" ]; then
            echo "$svn_path"
            return
        fi
    done
}

function svn_fetch ()
{
    cd "$src_path"
    if [ "$src_mode" == "packages" ]; then
        for package in $effective_packages; do
            src_path_pkg="$src_path$package"
            mkdir -p "$src_path_pkg" 2>/dev/null
            if [ "`$cmd_svn_test $src_path_pkg &>/dev/null; echo $?`" == 0 ]; then
                set_title "Updating sources in '$src_path_pkg' ..."
                echo "- updating sources in '$src_path_pkg' ..."
                if [ "$ask_on_src_conflicts" ]; then
                    backoff_loop "$cmd_svn_update_conflicts_ask $src_rev $package"
                else
                    backoff_loop "$cmd_svn_update_conflicts_solve $src_rev $package"
                fi
            else
                set_title "Checkout sources in '$src_path_pkg' ..."
                echo "- searching for direct source url for '$package' ..."
                path=`find_svn_path $package '' 1`
                if [ "$path" ]; then
                    src_url_pkg="$src_url/$path"
                    echo "- checkout sources in '$src_path_pkg' ..."
                    backoff_loop "$cmd_svn_checkout $src_rev $src_url_pkg $src_path_pkg"
                else
                    echo "- direct source url not found, package moved to OLD/?"
                fi
            fi
        done
    elif [ "$src_mode" == "full" ]; then
        if [ "`$cmd_svn_test &>/dev/null; echo $?`" == 0 ]; then
            set_title "Updating sources in '$src_path' ..."
            echo "- updating sources in '$src_path' ..."
            if [ "$ask_on_src_conflicts" ]; then
                backoff_loop "$cmd_svn_update_conflicts_ask $src_rev"
            else
                backoff_loop "$cmd_svn_update_conflicts_solve $src_rev"
            fi
        else
            set_title "Checkout sources in '$src_path' ..."
            echo "- checkout sources in '$src_path' ..."
            backoff_loop "$cmd_svn_checkout $src_rev $src_url $src_path"
        fi
    fi
}

function parse_svn_updates ()
{
    updated_packages=""
    for dir in `egrep "^[A|D|G|U] " "$tmp_path/source_update.log" | awk '{print $2}' | sed 's,[^/]*$,,g' | sort -u`; do
        add_pkg=""
        found=0
        for idir in $ignore_dirs; do
            topdir=`echo "$dir" | cut -d'/' -f1`
            if [ "$topdir" == "$idir" ]; then found=1; fi
        done
        if [ $found == 1 ]; then continue; fi
        for pkg in $effective_packages; do
            if [ `echo "$dir" | egrep -q "^$pkg/|/$pkg/"; echo $?` == 0 ]; then
                if [ ! `echo "$updated_packages" | egrep -q "^ $pkg | $pkg \$| $pkg "; echo $?` == 0 ]; then
                    updated_packages="$updated_packages $pkg"
                    echo "- $pkg"
                fi
                break
            fi
        done
    done
}


# SRC #############################################################################

function del_lines ()
{
    cnt=0
    max=$1
    while [ ! "$cnt" == "$max" ]; do
        echo -n -e "\b \b"
        cnt=$(($cnt+1))
    done
}

function rotate ()
{
    pid=$1
    name=$2
    animation_state=1
    log_line=""
    echo -n "   "
    while [ "`ps -p $pid -o comm=`" ]; do
        last_line=`tail -1 "$logs_path/$name.log"`
        if [ ! "$log_line" = "$last_line" ]; then
            echo -e -n "\b\b\b[\033[1m"
            case $animation_state in
                1)
                    echo -n "|"
                    animation_state=2
                    ;;
                2)
                    echo -n "/"
                    animation_state=3
                    ;;
                3)
                    echo -n "-"
                    animation_state=4
                    ;;
                4)
                    echo -n "\\"
                    animation_state=1
                    ;;
            esac
            echo -n -e "\033[0m"
            echo -n "]"
            log_line=$last_line
        fi
        sleep 1
    done
    if [ -e "$status_path/$name.noerrors" ]; then
        del_lines 12
    else
        del_lines 3
        echo -e "\033[1mERROR!\033[0m"
        set_notification "critical" "Package '$name': build failed"
        if [ ! "$skip_errors" ]; then
            set_title "$name: ERROR"
            echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
            echo
            echo -e "\033[1m-----------------------------------\033[7m Last loglines \033[0m\033[1m------------------------------\033[0m"
            echo -n -e "\033[1m"
            tail -25 "$logs_path/$name.log"
            echo -n -e "\033[0m"
            echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
            echo
            echo "-> Get more informations by checking the log file '$logs_path/$name.log'!"
            echo
            set_title
            exit 2
        fi
    fi
}

function error ()
{
    echo -e "\n\n\033[1mERROR: $1\033[0m\n\n"
    set_title "ERROR: $1"
    set_notification "critical" "Error: $1"
    exit 2
}

function logfile_banner ()
{
    cmd=$1
    logfile=$2
    echo "-------------------------------------------------------------------------------" >> "$logfile"
    echo "EASY_E17 $version CMD: $cmd"                                                       >> "$logfile"
    echo "-------------------------------------------------------------------------------" >> "$logfile"
}

function run_command ()
{
    name=$1
    path=$2
    title=$3
    log_title=$4
    mode_needed=$5
    cmd=$6
    set_title "$name: $title ($pkg_pos/$pkg_total)"
    echo -n "$log_title"
    logfile_banner "$cmd" "$logs_path/$name.log"
    if [ $mode_needed == "rootonly" ]; then
        mode_needed=$mode
    else
        if [ $nice_level -ge 0 ]; then
            mode_needed="user"
        fi
    fi
    rm -f $status_path/$name.noerrors
    case "$mode_needed" in
        "sudo")
            echo "$sudopwd" | sudo -S PKG_CONFIG_PATH="$PKG_CONFIG_PATH" PYTHONPATH="$PYTHONPATH" \
                               nice -n $nice_level $cmd >> "$logs_path/$name.log" 2>&1 && touch $status_path/$name.noerrors &
            ;;
        *)
            nice -n $nice_level $cmd >> "$logs_path/$name.log" 2>&1 && touch $status_path/$name.noerrors &
            ;;
    esac
    pid="$!"
    rotate "$pid" "$name"
}

function find_local_path ()
{
    name=$1
    path=""
    for dir in `find "$src_path" -maxdepth 3 -type d -name "$name" | awk -F "$src_path" '{print $2}'`; do
        found=0
        for idir in $ignore_dirs; do
            topdir=`echo "$dir" | cut -d'/' -f1`
            if [ "$topdir" == "$idir" ]; then found=1; fi
        done
        if [ $found == 1 ]; then continue; fi

        if [ "${#dir}" -lt "${#path}" ] || [ -z "$path" ]; then
            path=$dir
        fi
    done

    if [ "$path" ]; then echo "$src_path/$path"; fi
}

function compile ()
{
    name=$1
    if [ -e "$status_path/$name.installed" ]; then
        echo "previously installed"
        return
    fi
    path=`find_local_path $name`
    if [ ! -d "$path" ]; then
        echo "SOURCEDIR NOT FOUND"
        set_notification "critical" "Package '$name': sourcedir not found"
        return
    fi
    cd "$path"
    rm -f $status_path/$name.noerrors
    rm -f "$logs_path/$name.log"
    if [ $clean -ge 1 ]; then
        if [ -e "Makefile" ]; then
            if [ $clean -eq 1 ]; then
                run_command "$name" "$path" "clean" "clean  : " "$mode" "$make -j $threads clean"
                if [ ! -e "$status_path/$name.noerrors" ]; then
                    if [ "$skip_errors" ]; then
                        write_appname "$name" "hidden"    # clean might fail, that's ok
                    else
                        return
                    fi
                fi
            fi
            if [ $clean -eq 2 ]; then
                run_command "$name" "$path" "distclean" "distcln: " "$mode" "$make -j $threads clean distclean"
                if [ ! -e "$status_path/$name.noerrors" ]; then
                    if [ "$skip_errors" ]; then
                        write_appname "$name" "hidden"    # distclean might fail, that's ok
                    else
                        return
                    fi
                fi
            fi
            if [ $clean -ge 3 ]; then
                run_command "$name" "$path" "uninstall" "uninst : " "rootonly" "$make -j $threads uninstall clean distclean"
                if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
                # It's no longer installed if we just uninstalled it.
                # Even if the uninstall failed, it's best to mark it as uninstalled so that a partial uninstall gets fixed later.
                rm -f $status_path/$name.installed
            fi
        fi
    fi
    # get autogen arguments
    args=""
    for app_arg in `echo $autogen_args | tr -s '\,' ' '`; do
        app=`echo $app_arg | cut -d':' -f1`
        if [ "$app" == "$name" ]; then
            args="$args `echo $app_arg | cut -d':' -f2- | tr -s '+' ' '`"
        fi
    done
    if [ -e "autogen.sh" ]; then
        run_command "$name" "$path" "autogen" "autogen: " "$mode"    "./autogen.sh --prefix=$install_path $accache $args"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
        run_command "$name" "$path" "make"    "make:    " "$mode"    "$make -j $threads"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
        run_command "$name" "$path" "install" "install: " "rootonly" "$make install"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
    elif [ -e "bootstrap" ]; then
        run_command "$name" "$path" "bootstrap" "bootstr: " "$mode"    "./bootstrap"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
        run_command "$name" "$path" "configure" "config:  " "$mode"    "./configure --prefix=$install_path $accache $args"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
        run_command "$name" "$path" "make"      "make:    " "$mode"    "$make -j $threads"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
        run_command "$name" "$path" "install"   "install: " "rootonly" "$make install"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
    elif [ -e "Makefile.PL" ]; then
        run_command "$name" "$path" "perl"    "perl:    " "$mode"    "perl Makefile.PL prefix=$install_path $args"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
        run_command "$name" "$path" "make"    "make:    " "$mode"    "$make -j $threads"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
        run_command "$name" "$path" "install" "install: " "rootonly" "$make install"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
    elif [ -e "setup.py" ]; then
        run_command "$name" "$path" "python"   "python:  " "$mode"    "python setup.py build build_ext --include-dirs=$PYTHONINCLUDE $args"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
        run_command "$name" "$path" "install"  "install: " "rootonly" "python setup.py install --prefix=$install_path install_headers --install-dir=$PYTHONINCLUDE"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
    elif [ -e "Makefile" ]; then
        make_extra="PREFIX=$install_path"
        run_command "$name" "$path" "make"    "make:    " "$mode"    "$make $make_extra -j $threads"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
        run_command "$name" "$path" "install" "install: " "rootonly" "$make $make_extra install"
        if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
    else
        echo "no build system"
        set_notification "critical" "Package '$name': no build system"
        touch $status_path/$name.nobuild
        return
    fi

    if [ "$gen_docs" ]; then
        if [ -e "gendoc" ]; then
            run_command "$name" "$path" "docs" "docs   : " "$mode" "sh gendoc"
            if [ ! -e "$status_path/$name.noerrors" ] ; then return ; fi
        fi
    fi
    # All done, mark it as installed OK.
    touch $status_path/$name.installed
    rm -f $status_path/$name.noerrors
    echo "ok"
    set_notification "normal" "Package '$name': build successful"
}

function write_appname ()
{
    name=$1
    hidden=$2
    cnt=${#name}
    max=27
    if [ "$hidden" ]; then
        c=-3
        while [ ! $c = $cnt ]; do
            echo -n " "
            c=$(($c+1))
        done
    else
        echo -n "- $name "
    fi
    while [ ! $cnt = $max ]; do
        echo -n "."
        cnt=$(($cnt+1))
    done
    echo -n " "
}

function build_each ()
{
    pkg_pos=0
    for pkg in $packages; do
        pkg_pos=$(($pkg_pos+1))
        write_appname "$pkg"
        must=0
        for one in $updated_packages; do
            if [ "$pkg" == "$one" ]; then
                must=1
                break
            fi
        done
        for one in $only; do
            if [ "$pkg" == "$one" ]; then
                must=1
                break
            fi
        done
        if [ $must -eq 1 ]; then
            compile $pkg
        else
            echo "SKIPPED"
            touch $status_path/$name.skipped
        fi
    done
}


# SCRIPT: #############################################################################
EASY_PWD=`pwd`
my_args=$@
clean=0
accache=""
set_title
define_os_vars
read_config_files
parse_args
build_package_list
# check for script updates
if [ "$action" == "script" ]; then
    header
    check_script_version
fi
# Sanity check stuff if doing everything as user.
if [ "$asuser" ] && [ $nice_level -lt 0 ]; then
    nice_level=0
fi
# Fix issues with a slash at the end
if [ ! "${src_path:$((${#src_path}-1)):1}" == "/" ]; then
    src_path="$src_path/"
fi
# quit if some basic option is missing
if [ -z "$action" ] || [ -z "$install_path" ] || [ -z "$src_path" ]; then
    wrong
fi
header

# run script normally
open_header "Basic system checks"
check_commands "automake gcc $make `echo "$cmd_svn_checkout" | cut -d' ' -f1`"
echo -n "- creating temporary dirs .... "
mkdir -p "$tmp_path"        2>/dev/null
mkdir -p "$logs_path"        2>/dev/null
mkdir -p "$status_path"        2>/dev/null
mkdir -p "$src_cache_path"    2>/dev/null
mkdir -p "$src_path"        2>/dev/null
chmod 700 "$tmp_path"
echo "ok"
if [ ! "$action"  == "srcupdate" ]; then
    check_build_user
    set_build_env
    mk_dest_dirs
    check_ld_path
fi

# sources
open_header "Source checkout/update"
if [ -z "$skip_srcupdate" ]; then
    rm "$tmp_path/source_update.log" 2>/dev/null
    cd "$src_path"
    if [ "`$cmd_svn_test &>/dev/null; echo $?`" == 0 ]; then
        if [ "$src_mode" == "packages" ]; then
            echo -e "\033[1m- Full checkout found, changed source mode to 'full'!\033[0m"
            src_mode="full"
        fi
    fi
    svn_fetch
else
    echo -e "\n                                - - - SKIPPED - - -\n"
fi

# parse updates
if [ "$action" == "update" ] && [ -e "$tmp_path/source_update.log" ]; then
    open_header "Parsing updates"
    parse_svn_updates
    if [ -z "$updated_packages" ]; then
        echo -e "\n                         - - - NO UPDATES AVAILABLE - - -\n"
    fi
fi
pkg_total=`echo "$updated_packages" | wc -w`

# build/install
open_header "Compilation & installation"
if [ "$action" == "install" ]; then
    set_notification "normal" "Now building packages..."
elif [ "$action" == "only" ]; then
    set_notification "normal" "Now building following packages: $updated_packages"
elif [ "$action" == "update" ]; then
    if [ "$updated_packages" ]; then
        set_notification "normal" "Now building following packages: $updated_packages"
    else
        set_notification "normal" "Everything is up to date, nothing to build"
    fi
fi
build_each

# Restore current directory in case post processing wants to be pathless.
open_header "Finish installation"
cd $EASY_PWD
echo -n "- registering libraries ...... "
if [ -z "$asuser" ]; then
    case "$mode" in
        "sudo") echo "$sudopwd" | sudo -S nice -n $nice_level $ldconfig > /dev/null 2>&1 ;;
        *) nice -n $nice_level $ldconfig > /dev/null 2>&1 ;;
    esac
    echo "ok"
else
    echo "skipped"
fi
echo -n "- post install script ........ "
if [ "$easy_e17_post_script" ]; then
    echo -n " '$easy_e17_post_script' ... "
    case "$mode" in
        "sudo") echo "$sudopwd" | sudo -S nice -n $nice_level $easy_e17_post_script ;;
        *) nice -n $nice_level $easy_e17_post_script ;;
    esac
    echo "ok"
else
    echo "skipped"
fi
echo -n "- check compilation logs ..... "
for file in $logs_path/*.log ; do
    if [ "$file" == "$logs_path/*.log" ]; then break; fi
    pkg=`basename "$file" | cut -d'.' -f1`
    if [ -e "$status_path/$pkg.installed" ]; then
        packages_installed="$packages_installed $pkg"
    else
        if [ -e "$status_path/$pkg.skipped" ]; then
            packages_skipped="$packages_skipped $pkg"
        else
            if [ -e "$status_path/$pkg.nobuild" ]; then
                    packages_nobuild="$packages_nobuild $pkg"
            else    packages_failed="$packages_failed $pkg"; fi
        fi
    fi
done
echo "ok"
if [ -z "$keep" ]; then
    if [ "$packages_failed" ]; then
        echo -n "- saving logs ................ "
        for pkg in $packages_installed; do
            rm "$status_path/$pkg.installed" 2>/dev/null
            rm "$logs_path/$pkg.log" 2>/dev/null
        done
    else
        echo -n "- deleting temp dir .......... "
        rm -rf $tmp_path 2>/dev/null
    fi
    echo "ok"
else
    echo "- saving temp dir ............ ok"
fi

if [ "$packages_failed" ]; then
    open_header "Failed packages"
    for pkg in $packages_failed; do
        echo "- $pkg (error log: $logs_path/$pkg.log)"
    done
    set_notification "critical" "Script finished with build errors"
else
    set_notification "normal" "Script finished successful"
fi
if [ "$action" == "install" ]; then
    open_header "INSTALL NOTES:"
    echo "The most incredible and really unbelievable dream has become true:"
    echo "You compiled e17 successfully!"
    echo
    echo "Starting e17:"
    echo "Create a file ~/.xsession with the line 'exec $install_path/bin/enlightenment_start'."
    echo "Add a link to this file using 'ln -s ~/.xsession ~/.xinitrc'."
    echo
    echo "If you're using a login manager (GDM/KDM), select the session type 'default' in them."
    echo "If you're using the startx command, simply execute it now."
    echo
    echo "Note: e17 is still not released and it won't be in the near future. So don't"
    echo "ask for a stable release. e17 is still very buggy and only for experienced users"
    echo "who know what they do..."
    echo
    echo "Rasterman didn't write this script so don't ask him for help with it."
    echo
    echo "Hint: From now on you can easily keep your installation up to date."
    echo "Simply run easy_e17.sh with -u instead of -i ."
    echo
    echo "We hope you will enjoy your trip into e17... Have fun!"
    echo -e "\033[1m--------------------------------------------------------------------------------\033[0m"
fi
open_header "usefull environment variables"
echo "  export PATH=\"$install_path/bin:\$PATH\""
echo "  export PYTHONPATH=\"`python -c \"import distutils.sysconfig; print distutils.sysconfig.get_python_lib(prefix='$install_path')\" 2>/dev/null`:\$PYTHONPATH\""
echo "  export LD_LIBRARY_PATH=\"$install_path/lib:\$LD_LIBRARY_PATH\""
# Clear this out if we ever set it.
export CC=""
# exit script or wait?
if [ "$wait" ]; then
    echo
    echo -e -n "\033[1mThe script is waiting here - simply press [enter] to exit.\033[0m"
    read
fi
set_title
if [ "$packages_failed" ]; then
        exit 2
else
    exit 0
fi
