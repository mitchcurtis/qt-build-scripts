#! /bin/bash

set -e
set -o pipefail

startTime=$SECONDS

# Using realpath ensures the script works even if relative paths are passed.
# Try to get the absolute, full path of the argument using realpath. If that works, save the result.
# If realpath creates an error, hide the error message and just use the original path instead.
topLevelSourceDir=$(realpath "$1" 2>/dev/null || echo "$1")
topLevelBuildDir=$(realpath "$2" 2>/dev/null || echo "$2")
configPath=$(realpath "$3" 2>/dev/null || echo "$3")
submoduleStr=$4

usageExample="Usage example: clean-rebuild-qt-cmake-linux.sh ~/dev/qt-dev ~/dev/qt-dev-debug ../configs/linux-debug.txt qtbase,qtsvg,qtshadertools,qtdeclarative"

# Validate arguments.
if [ -z "$1" ]; then
    echo "topLevelSourceDir argument not supplied"
    echo "$usageExample"
    exit 1
fi

if [ -z "$2" ]; then
    echo "topLevelBuildDir argument not supplied"
    echo "$usageExample"
    exit 1
fi

if [ -z "$3" ]; then
    echo "configPath argument not supplied"
    echo "$usageExample"
    exit 1
fi

if [ -z "$4" ]; then
    echo "submoduleStr argument not supplied"
    echo "$usageExample"
    exit 1
fi

# Ensure required tools are installed before starting the process.
for tool in ninja cmake head realpath; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: Required tool '$tool' not found in PATH; aborting."
        exit 1
    fi
done

if [ ! -d "$topLevelSourceDir" ]; then
    echo "ERROR: Source directory \"$topLevelSourceDir\" doesn't exist; aborting"
    echo "$usageExample"
    exit 1
fi

echo "=== reading configure options from $configPath"
configOptions=$(head -n 1 "$configPath")

if [ "$configOptions" = "" ]; then
    echo "ERROR: Must pass one or more configure options"
    exit 1
fi

echo "=== configure options are: $configOptions"

IFS="," read -a submodules <<<"$submoduleStr"
echo "=== submodules are: ${submodules[*]}"

if [ ${#submodules[@]} -eq 0 ]; then
    echo "ERROR: Must pass one or more submodules"
    exit 1
fi

qtbaseToken="qtbase"
if [[ ! "${submodules[0]}" =~ "${qtbaseToken}" ]]; then
    echo "ERROR: submoduleStr argument must contain qtbase (was: \"$submoduleStr\")"
    exit 1
fi

# Only wipe the build directory if CMakeCache.txt exists in qtbase.
if [ -d "$topLevelBuildDir" ]; then
    # The build directory exists.
    if [ "$(ls -A "$topLevelBuildDir")" ]; then
        # It's not empty.
        if [ ! -f "$topLevelBuildDir/qtbase/CMakeCache.txt" ]; then
            echo "ERROR: $topLevelBuildDir is not empty and $topLevelBuildDir/qtbase/CMakeCache.txt was not found."
            echo "For safety, the script will not 'rm -rf' this directory."
            echo "Please delete it manually or check your paths."
            exit 1
        fi
    fi
fi

echo "=== wiping $topLevelBuildDir"
rm -rf "$topLevelBuildDir"

echo "=== creating $topLevelBuildDir"
mkdir -p "$topLevelBuildDir"

echo "=== cding to $topLevelBuildDir"
cd "$topLevelBuildDir"

export LLVM_INSTALL_DIR=/usr/lib/llvm-18

# Configure and build each module within the top-level build directory.
for moduleName in "${submodules[@]}"
do
    echo "=== processing module: $moduleName"
    mkdir -p "$moduleName"
    cd "$moduleName"

    echo "=== configuring module $moduleName"
    if [ "$moduleName" = "$qtbaseToken" ]; then
        "$topLevelSourceDir/qtbase/configure" -- $configOptions 2>&1 | tee configure-output.txt
    else
        "$topLevelBuildDir/qtbase/bin/qt-configure-module" "$topLevelSourceDir/$moduleName" 2>&1 | tee configure-output.txt
    fi

    echo "=== building module $moduleName"
    ninja 2>&1 | tee ninja-output.txt

    echo "=== cding back to $topLevelBuildDir"
    cd "$topLevelBuildDir"
done

# Print build times.
endTime=$SECONDS
duration=$(( endTime - startTime ))
minutes=$(( duration / 60 ))
seconds=$(( duration % 60 ))

echo "==="
echo "Build finished successfully at: $(date +'%H:%M:%S')"
echo "Total time: $minutes minute(s) and $seconds second(s)"
