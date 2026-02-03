#!/bin/bash

usageExample="Usage: cd ~/dev/qt-dev/qtdeclarative && git fetch && git reset --hard origin/dev && cd .. && qt-git-sync-to.sh qtdeclarative HEAD"

if [ -z "$1" ]; then
    echo "module argument not supplied"
    echo $usageExample
    exit 1
fi

if [ -z "$2" ]; then
    echo "ref argument not supplied"
    echo $usageExample
    exit 1
fi

foundCmakeFile=false
while [[ "$PWD" != "/" ]]
do
    if [ -f cmake/QtSynchronizeRepo.cmake ]
    then
        echo "found cmake file in $PWD"
        foundCmakeFile=true
        break
    fi

    cd ..
done

if [ "$foundCmakeFile" = false ]
then
    echo "This script needs to be run within a Qt supermodule clone"
    echo $usageExample
    exit 1
fi

module="$1"
shift
revision="$1"
shift

if [ ! -d $module ]
then
    echo "Can't find module '$module'"
    exit 1
fi

git fetch

cmake -DSYNC_TO_MODULE="$module" -DSYNC_TO_BRANCH="$revision" "$@" -P cmake/QtSynchronizeRepo.cmake
