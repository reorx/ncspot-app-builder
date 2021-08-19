#!/bin/bash

set -eu

ALACRITTY_VERSION=v0.9.0
ALACRITTY_NAME="Alacritty-$ALACRITTY_VERSION.dmg"
NCSPOT_VERSION=v0.8.1
NCSPOT_NAME="ncspot-$NCSPOT_VERSION-macos.tar.gz"
: ${NCSPOT_BIN:=""}

build_dir="build"
download_dir="build/download"
dist_dir="dist"
arch="$(uname -m)"

app_build="$build_dir/ncspot-$arch.app"
app_bin="$app_build/Contents/MacOS"

clear() {
    rm -rf "$app_build"
}

main() {
    mkdir -p build/download dist

    clear

    echo "Copy app bundle template"
    cp -r app_bundle.app $app_build
    rm $app_bin/app_bundle.sh
    cp assets/ncspot.sh $app_bin

    echo "Change Info.plist"
    gsed -i -e 's/app_bundle/ncspot/' $app_build/Contents/Info.plist

    echo "Change icon"
    cp assets/AppIcon.icns $app_build/Contents/Resources/

    echo "Extract packages.."
    pushd "$download_dir"
    rm -rf Alacritty
    7z x $ALACRITTY_NAME >/dev/null

    rm -f ncspot
    tar xzf $NCSPOT_NAME
    popd

    echo "Copy alacritty executable"
    cp $download_dir/Alacritty/Alacritty.app/Contents/MacOS/alacritty "$app_bin"
    chmod 755 "$app_bin/alacritty"

    echo "Copy ncspot executable"
    if [ -z "$NCSPOT_BIN" ]; then
        NCSPOT_BIN="$download_dir/ncspot"
    fi
    cp "$NCSPOT_BIN" "$app_bin"
    chmod 755 "$app_bin/ncspot"

    echo "Copy and link dylib"
    if [ "$arch" = "arm64" ]; then
        pushd $app_bin
        libportaudio_path="$(otool -L ncspot | grep libportaudio | awk '{ print $1 }')"
        cp -L "$libportaudio_path" .
        install_name_tool -change "$libportaudio_path" "@executable_path/${libportaudio_path##/*/}" ncspot
        popd
    else
        echo "WARNING dylib not packed with the app, please send PR to fix this"
    fi

    echo "Remove app quarantine"
    xattr -dr com.apple.quarantine "$app_build"
}

download_if_missing() {
    local filename="${1##http*/}"
    if [ -e "$filename" ]; then
        echo "$filename exists"
    else
        echo "Download $filename.."
        curl "$1" -L -o "$download_dir/${1##http*/}"
    fi
}

run_update() {
    mkdir -p build/download

    download_if_missing "https://github.com/alacritty/alacritty/releases/download/$ALACRITTY_VERSION/$ALACRITTY_NAME"
    echo
    download_if_missing "https://github.com/hrkfdn/ncspot/releases/download/$NCSPOT_VERSION/$NCSPOT_NAME"
}

show_usage() {
    echo "Usage: $0 [-u | -h]"
    echo "Options:\n  -u\tupdate dependencies\n  -h\tshow help"
}


while getopts ":hu" opt; do
    case "${opt}" in
        u)
            run_update
            exit
            ;;
        h)
            show_usage
            exit
            ;;
    esac
done

main
