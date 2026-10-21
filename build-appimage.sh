
#!/usr/bin/env bash
set -e

# Config
icon_path="Icons/Zakuro.png"
executable_path="./Zakuro-bin"
desktop_file_path="./Zakuro.desktop"
appimage_filename="Zakuro-x86_64.AppImage"
appdir="./Zakuro.AppDir"
libudev_path="/lib64/libudev.so.1"
libasound_path="/lib64/libasound.so.2"

icons=(
  "Icons/Zakuro@0.5x.png"
  "Icons/Zakuro@2x.png"
  "Icons/Zakuro@3x.png"
)

icon_sizes=("128x128" "512x512" "768x768")

prepare_binary(){
curl -s https://api.github.com/repos/fearkov/zakuro/releases/latest |
  jq -r '.assets[] | select(.name | test("linux.*x86_64|x86_64.*linux"; "i")) | .browser_download_url' |
  xargs -r -n1 curl -fLO
  tar -xvf zakuro-linux-x86_64.tar.gz
  mv zakuro Zakuro-bin
}

build() {
  linuxdeploy \
    --executable "$executable_path" \
    -l $libudev_path \
    -l $libasound_path \
    --desktop-file "$desktop_file_path" \
    --icon-file "$icon_path" \
    --appdir "$appdir"
}

include_icons() {
  local i
  local icon_dir

  for i in "${!icons[@]}"; do
    icon_dir="$appdir/usr/share/icons/hicolor/${icon_sizes[$i]}/apps"
    mkdir -p "$icon_dir"
    cp "${icons[$i]}" "$icon_dir/Zakuro.png"
  done
}

package() {
  OUTPUT="$appimage_filename" linuxdeploy --appdir "$appdir" --output appimage
}

# Commit then publish to github (Optional requires login)
publish_to_github(){
}

cleanup(){
  rm zakuro-linux-x86_64.tar.gz
  rm LICENSE
  rm README.md
}

prepare_binary
build
include_icons
package
