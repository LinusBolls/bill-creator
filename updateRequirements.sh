#!/bin/sh

LAUNCH_PATH=$(
  cd "$(dirname "$0")"
  pwd
)

TXT="$LAUNCH_PATH/requirements.txt"
FOLDER="$LAUNCH_PATH/requirements"
ZIP="$LAUNCH_PATH/requirements.zip"

rm "$TXT" 2>/dev/null
rm -r "$FOLDER" 2>/dev/null
rm "$ZIP" 2>/dev/null

/usr/bin/pip3 freeze >"$TXT"

# remove last line which causes errors on install
sed -i "" -e "$ d" "$TXT"

$env /usr/bin/arch -x86_64 /usr/bin/pip3 install -r "$TXT" -t "$FOLDER"

# using an absolute path for the second zip arguments creates nested folders _inside_ the zip,
# so we are cding to avoid having to use it
cd "$LAUNCH_PATH"
zip -r "$ZIP" "requirements"
