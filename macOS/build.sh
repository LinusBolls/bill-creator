#!/bin/sh

# https://stackoverflow.com/questions/96882/how-do-i-create-a-nice-looking-dmg-for-mac-os-x-using-command-line-tools
# https://github.com/create-dmg/create-dmg

LAUNCH_PATH=$(
  cd "$(dirname "$0")"
  pwd
)
APP_PATH="$LAUNCH_PATH/.."

DMG_FILE="$LAUNCH_PATH/Der Schuldner.dmg"

rm "$DMG_FILE" 2>/dev/null

echo "launch_path: $LAUNCH_PATH"
echo "app_path: $APP_PATH"

toIconSet() {

  FOLDER="$APP_PATH/macOS/appIcon"
  SVG_FILE="$APP_PATH/assets/appIcon.svg"
  PNG_FILE="$APP_PATH/macOS/appIcon.png"

  # qlmanage -t -s 1024 -o . "$SVG_FILE"

  # brew install librsvg required for rsvg-convert
  rsvg-convert -h 1024 "$SVG_FILE" >"$PNG_FILE"

  mkdir "$FOLDER"

  # sips -z 16 16 "$PNG_FILE" --out "$Folder/icon_16x16.png"
  # sips -z 32 32 "$PNG_FILE" --out "$Folder/icon_16x16@2x.png"
  # sips -z 32 32 "$PNG_FILE" --out "$Folder/icon_32x32.png"
  # sips -z 64 64 "$PNG_FILE" --out "$Folder/icon_32x32@2x.png"
  # sips -z 128 128 "$PNG_FILE" --out "$Folder/icon_128x128.png"
  # sips -z 256 256 "$PNG_FILE" --out "$Folder/icon_128x128@2x.png"
  # sips -z 256 256 "$PNG_FILE" --out "$Folder/icon_256x256.png"
  # sips -z 512 512 "$PNG_FILE" --out "$Folder/icon_256x256@2x.png"
  # sips -z 512 512 "$PNG_FILE" --out "$Folder/icon_512x512.png"
  cp "$PNG_FILE" "$FOLDER/icon_512x512@2x.png"

  # sips -s format icns "$FOLDER/icon_512x512@2x.png" --out appIcon.icns

  iconutil -c icns "$FOLDER"

  rm -R "$FOLDER"
  rm "$PNG_FILE"
}
toIconSet

BACKGROUND_IMG_PATH="$APP_PATH/assets/dmgBackground.png"
applicationName=Der\ Schuldner.app
title="Installiere den Schuldner"
source="$LAUNCH_PATH/Der Schuldner.app"

mkdir "$LAUNCH_PATH/temp/"
cp -r "$LAUNCH_PATH/Der Schuldner.app" "$LAUNCH_PATH/temp/"
cp -fr "$APP_PATH/requirements.zip" "$LAUNCH_PATH/temp/Der Schuldner.app/Contents"
ln -s /Applications "$LAUNCH_PATH/temp/Applications"
hdiutil create -fs HFS+ -srcfolder "$LAUNCH_PATH/temp/" -volname "$title" "$DMG_FILE"
rm -r "$LAUNCH_PATH/temp/"

sache="$LAUNCH_PATH/pack.temp.dmg"

# ab hier wirds sus

# hdiutil create -srcfolder "${source}" -volname "${title}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 500m "$sache"

# device=$(hdiutil attach -readwrite -noverify -noautoopen "$sache" | \
#          egrep '^/dev/' | sed 1q | awk '{print $1}')

# echo '
#    tell application "Finder"
#      tell disk "'${title}'"
#            open
#            set current view of container window to icon view
#            set toolbar visible of container window to false
#            set statusbar visible of container window to false
#            set the bounds of container window to {400, 100, 885, 430}
#            set theViewOptions to the icon view options of container window
#            set arrangement of theViewOptions to not arranged
#            set icon size of theViewOptions to 72
#            set background picture of theViewOptions to file ".background:'${BACKGROUND_IMG_PATH}'"
#            make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
#            set position of item "'${applicationName}'" of container window to {100, 100}
#            set position of item "Applications" of container window to {375, 100}
#            update without registering applications
#            delay 5
#            close
#      end tell
#    end tell
# ' | osascript

# chmod -Rf go-w /Volumes/"${title}"
# sync
# sync
# hdiutil detach ${device}
# hdiutil convert "$sache" -format UDZO -imagekey zlib-level=9 -o "dings"
# rm -f "$sache"

# sips -Z 2000 background.png --out resizedBackground.png
