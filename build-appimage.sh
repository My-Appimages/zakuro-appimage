#!/usr/bin/env bash
set -Eeuo pipefail

source ./config.sh
version=""

while (($#)); do
  case "$1" in
    --version|-v)
      if [[ -z "${2:-}" ]]; then
        echo "ERROR: --version requires a version number." >&2
        exit 1
      fi
      version="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--version VERSION]"
      echo "  --version, -v  Download a specific release tag"
      echo "  --help, -h     Show this help"
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

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
  local asset_url
  local extracted_dir
  local api_url
  local release_json

  if [[ -n "$version" ]]; then
    api_url="https://api.github.com/repos/fearkov/zakuro/releases/tags/$version"
    echo "Downloading Zakuro version: $version"
  else
    api_url="https://api.github.com/repos/fearkov/zakuro/releases/latest"
    echo "Downloading latest Linux x86-64 binary..."
  fi

  # Fetch release metadata.
  release_json="$(curl -fsSL "$api_url")" || {
    echo "ERROR: Failed to fetch release metadata: $api_url" >&2
    return 1
  }

  # Find the Linux x86_64 archive URL.
  asset_url="$(
    jq -er '
      [
        .assets[]
        | select(.name | test("linux-x86_64\\.tar\\.gz$"; "i"))
      ]
      | if length == 1 then
          .[0].browser_download_url
        else
          error("Expected exactly one Linux x86_64 tar.gz asset")
        end
    ' <<< "$release_json"
  )" || {
    echo "ERROR: Could not find the expected Linux x86_64 archive." >&2
    jq -r '.tag_name, (.assets[]?.name)' <<< "$release_json" >&2
    return 1
  }

  echo "Downloading archive: $asset_url"
  curl -fL --retry 3 "$asset_url" -o "$archive"

  # Start with a clean build directory.
  tar -xzf "$archive"

  [[ -f zakuro ]] || {
    echo "ERROR: Archive does not contain a file named zakuro" >&2
    return 1
  }

  mv zakuro "$executable_path"
  chmod +x "$executable_path"
}


build() {
  local libudev_path
  #local libasound_path

  libudev_path="$(find_library libudev.so.1)"
  #libasound_path="$(find_library libasound.so.2)"

  echo "Using libudev: $libudev_path"
  #echo "Using libasound: $libasound_path"

  linuxdeploy \
    --executable "$executable_path" \
    -l "$libudev_path" \
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
