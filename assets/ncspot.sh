#!/bin/bash

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
DIR_PATH="$(dirname "$SCRIPT_PATH")"

"$DIR_PATH/alacritty" --title "ncspot" -e "$DIR_PATH/ncspot"
