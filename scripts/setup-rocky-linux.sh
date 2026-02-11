#! /bin/bash

set -e
set -o pipefail

mkdir ~/dev
gsettings set org.gnome.desktop.session idle-delay 0
