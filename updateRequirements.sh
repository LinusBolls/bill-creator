#!/bin/sh

DIR=`dirname $0`
TXT="$DIR/requirements.txt"
FOLDER="$DIR/requirements"
ZIP="$DIR/requirements.zip"

rm "$TXT"
rm -r "$FOLDER"
rm "$ZIP"

pip3 freeze > "$TXT"
# remove last line which causes errors on install
sed -i "" -e "$ d" "$TXT"
pip3 install -r "$TXT" -t "$FOLDER"
zip -r "$ZIP" "$FOLDER"