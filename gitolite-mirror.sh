#! /bin/bash

if [ $# -lt 1 ]; then
    echo "missing gitolite config file"
    exit 1
fi

RESET="\033[0m"
GREEN="\033[0;32m"

GIT_URI=${GIT_URI:-"git://asynk.ch"}
GITOLITE_CONF=$1

cat $GITOLITE_CONF | grep '^repo' | sed 's/repo\s\+//' | while read repo; do
    echo -e "** >$GREEN$repo$RESET<"
    if [ -d "${repo}" ]; then
        cd $repo
        git remote update --prune
        cd ..
    else
        git clone --mirror $GIT_URI/${repo}.git $repo
    fi
done
