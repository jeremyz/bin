#! /bin/bash

if [ $# -lt 5 ]; then
    echo "usage $0 ProjPath PackageName ProjName ActivityName TargetID"
    exit 1
fi

PPATH=$1
PKG=$2
PNAME=$3
ANAME=$4
TARGET=$5

RESET="\033[0m"
RED="\033[0;31m"
BROWN="\033[0;33m"

function run ()
{
    echo -e "${RED}* ${BROWN}${1} ${RESET}"
    $1 || exit 1
}

run "android create project --path ${PPATH} --target ${TARGET} --package ${PKG} --name ${PNAME} --activity ${ANAME}"
run "android create test-project --path ${PPATH}/tests --name ${PNAME}Test --main ../"

run "cd $PPATH"
run "ant instrument"
run "ant instrument install"
#run "adb -s emulator-5554 install -r bin/${PNAME}-instrumented.apk"

run "cd tests"
run "ant instrument"
run "ant instrument install"
#run "adb -s emulator-5554 install -r bin/${PNAME}Test-instrumented.apk"

run "adb shell am instrument -e coverage true -w ${PKG}.tests/android.test.InstrumentationTestRunner"

run "adb shell pm uninstall ${PKG}"
run "adb shell pm uninstall ${PKG}.tests"
