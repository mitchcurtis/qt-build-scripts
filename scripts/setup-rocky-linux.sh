#! /bin/bash

# This is designed to create a testing environment as close to linux-RHEL-10.0-x86_64 as possible.

set -e
set -o pipefail

# Disable screen lock.
gsettings set org.gnome.desktop.session idle-delay 0

# Escape from Vim.
sudo dnf install epel-release -y
sudo dnf install gedit -y
git config --global core.editor "gedit"

# We need this to clone the provisioning scripts.
qtSourceDir=$(realpath "$1" 2>/dev/null || echo "$1")
rhelProvisioningScriptsDir="$qtSourceDir/coin/provisioning/qtci-linux-RHEL-10.0-x86_64"

usageExample="Usage example: setup-rocky-linux.sh ~/dev/qt-dev"

# Validate arguments.
if [ -z "$1" ]; then
    echo "qtSourceDir argument not supplied"
    echo "$usageExample"
    exit 1
fi

# Check that provisioning scripts exist.
if [ -z "$rhelProvisioningScriptsDir" ]; then
    echo "RHEL provisioning scripts directory doesn't exist: $rhelProvisioningScriptsDir"
    echo "$usageExample"
    exit 1
fi

cd $rhelProvisioningScriptsDir

# Make all .sh files executable.
chmod +x *.sh

./01-disable_net_lso.sh

# Probably not needed.
#01-install_telegraf.sh
#01-refresh-subscription-manager.sh
#01-remove_network_manager_secret_key.sh

# We don't build webengine.
#01-set-ulimit.sh

./01-systemsetup.sh
./02-install-xcb_util_cursor.sh

# May need this; let´s see.
#03-enable-repos.sh

./03-limit-avahi-interfaces.sh
./04-install-packages.sh
./04-p7zip.sh
./05-install-ninja.sh
./05-install-patchelf.sh
./05-libclang-dyn.sh
./05-libclang.sh
./05-mount-vcpkg-cache-drive.sh

# Probably don't need these.
#09-disable_selinux.sh
#20-sccache.sh
#22-mqtt_broker.sh
#30-fbx.sh

./30-install-conan.sh
./30-install-git.sh
./30-install_icu.sh

# Don't need, and requires CI network.
#35-install-breakpad.sh

# Needed if testing Android stuff, but we´ŕe not.
#38-maven.sh
#40-android_linux.sh
#41-install-bundletool.sh
#50-openssl_for_android_linux.sh

./40-install-cmake.sh
./41-install-golang.sh
./41-install-upx.sh
./41-install-vcpkg.sh
./42-install-vcpkg-ports.sh

#51-openapi.sh

./60-install_protobuf.sh
./61-install_grpc.sh
./70-install_dwz.sh

# Not needed since we´re running our own VM.
#70-install_QemuGA.sh

./90-bootstrap-autostart.sh

#90-firebird.sh

./90-install-ffmpeg.sh

#90-install-oracle.sh
#90-mimer.sh

# Probably don´t need to run this every time?
#99-cleanup.sh

./99-enable_test_stacktraces.sh

#99-network-test.sh

#99-version.sh

