
#!/usr/bin/env bash
set -Eeuo pipefail

# Config
icon_path="Icons/Zakuro.png"
executable_path="./Zakuro-bin"
desktop_file_path="./Zakuro.desktop"
appimage_filename="Zakuro-x86_64.AppImage"
appdir="./Zakuro.AppDir"

icons=(
  "Icons/Zakuro@0.5x.png"
  "Icons/Zakuro@2x.png"
  "Icons/Zakuro@3x.png"
)

icon_sizes=("128x128" "512x512" "768x768")

# Find a library using the system linker cache.
find_library() {
  local lib="$1"
  local path

  path="$(ldconfig -p | awk -v lib="$lib" '$1 == lib { print $NF; exit }')"

  if [[ -z "$path" || ! -e "$path" ]]; then
    echo "ERROR: Required library not found: $lib" >&2
    return 1
  fi

  printf '%s\n' "$path"
}

prepare_binary() {
  echo "Downloading latest Linux x86-64 binary..."

  local api_url="https://api.github.com/repos/fearkov/zakuro/releases/latest"
  local asset_url

  asset_url="$(
    curl -fsSL "$api_url" |
      jq -er '
        [
          .assets[]
          | select(.name | test("linux-x64\\.tar\\.gz$"; "i"))
        ]
        | if length == 1 then
            .[0].browser_download_url
          else
            error("Expected exactly one Linux x64 tar.gz asset")
          end
      '
  )"

  curl -fL --retry 3 "$asset_url" -o "$archive"
  tar -xzf zakuro-linux-x86_64.tar.gz

  mv zakuro "$executable_path"
  chmod +x "$executable_path"
}

build() {
  local libudev_path
  local libasound_path

  libudev_path="$(find_library libudev.so.1)"
  libasound_path="$(find_library libasound.so.2)"

  echo "Using libudev: $libudev_path"
  echo "Using libasound: $libasound_path"

  linuxdeploy \
    --executable "$executable_path" \
    -l "$libudev_path" \
    -l "$libasound_path" \
    --desktop-file "$desktop_file_path" \
    --icon-file "$icon_path" \
    --appdir "$appdir"
}

include_icons() {
  local i
  local icon_dir

  for i in "${!icons[@]}"; do
    [[ -f "${icons[$i]}" ]] || {
      echo "ERROR: Missing icon: ${icons[$i]}" >&2
      return 1
    }

    icon_dir="$appdir/usr/share/icons/hicolor/${icon_sizes[$i]}/apps"
    mkdir -p "$icon_dir"
    cp "${icons[$i]}" "$icon_dir/Zakuro.png"
  done
}

package() {
  OUTPUT="$appimage_filename" \
    linuxdeploy --appdir "$appdir" --output appimage

  [[ -f "$appimage_filename" ]] || {
    echo "ERROR: AppImage was not created!" >&2
    return 1
  }

  chmod +x "$appimage_filename"
  echo "Built successfully: $appimage_filename"
}

prepare_binary
build
include_icons
package
