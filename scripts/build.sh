#!/bin/bash
set -euo pipefail

VERSION="${1:-0.1.0}"
BUILD_DIR="build/releases"
mkdir -p "$BUILD_DIR"

echo "=== Building Blink v${VERSION} ==="

# macOS
build_macos() {
  echo "--- Building macOS ---"
  flutter build macos --release

  APP_PATH="build/macos/Build/Products/Release/blink_app.app"
  DMG_PATH="${BUILD_DIR}/Blink-${VERSION}-macos.dmg"

  # Create DMG
  if command -v create-dmg &> /dev/null; then
    create-dmg \
      --volname "Blink" \
      --window-pos 200 120 \
      --window-size 600 400 \
      --icon-size 100 \
      --app-drop-link 400 185 \
      "$DMG_PATH" \
      "$APP_PATH"
  else
    # Fallback: simple hdiutil
    hdiutil create -volname "Blink" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"
  fi

  echo "macOS DMG: $DMG_PATH"
}

# Windows
build_windows() {
  echo "--- Building Windows ---"
  flutter build windows --release

  WINDOWS_DIR="build/windows/x64/runner/Release"
  ZIP_PATH="${BUILD_DIR}/Blink-${VERSION}-windows.zip"

  # Zip the release folder
  cd "$WINDOWS_DIR"
  zip -r "../../../../$ZIP_PATH" .
  cd -

  echo "Windows ZIP: $ZIP_PATH"
}

# Linux
build_linux() {
  echo "--- Building Linux ---"
  flutter build linux --release

  LINUX_DIR="build/linux/x64/release/bundle"

  # Create AppImage structure
  APPDIR="${BUILD_DIR}/Blink.AppDir"
  mkdir -p "${APPDIR}/usr/bin" "${APPDIR}/usr/share/icons"
  cp -r "${LINUX_DIR}/." "${APPDIR}/usr/bin/"

  # AppRun
  cat > "${APPDIR}/AppRun" << 'APPRUN'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
exec "${HERE}/usr/bin/blink" "$@"
APPRUN
  chmod +x "${APPDIR}/AppRun"

  # Desktop file
  cat > "${APPDIR}/blink.desktop" << 'DESKTOP'
[Desktop Entry]
Name=Blink
Exec=blink
Icon=blink
Type=Application
Categories=Utility;
Comment=Smart break reminders for healthy screen habits
DESKTOP

  # Create tarball (AppImage tool needed for actual .AppImage)
  TAR_PATH="${BUILD_DIR}/Blink-${VERSION}-linux.tar.gz"
  tar -czf "$TAR_PATH" -C "$LINUX_DIR" .

  echo "Linux tarball: $TAR_PATH"
}

# Build based on platform
case "${2:-all}" in
  macos)  build_macos ;;
  windows) build_windows ;;
  linux)  build_linux ;;
  all)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      build_macos
    elif [[ "$OSTYPE" == "linux"* ]]; then
      build_linux
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
      build_windows
    fi
    ;;
esac

echo "=== Build complete ==="
