#!/bin/bash
set -euo pipefail

# Chirp icon generation script
# Converts source SVGs to all platform-specific PNGs and ICOs
# Requirements: rsvg-convert (librsvg), magick (ImageMagick)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BRAND_DIR="${PROJECT_DIR}/assets/branding"

# Verify tools
command -v rsvg-convert >/dev/null || { echo "Error: Install librsvg: brew install librsvg"; exit 1; }
command -v magick >/dev/null || { echo "Error: Install ImageMagick: brew install imagemagick"; exit 1; }

SVG_ICON="${BRAND_DIR}/chirp_logo.svg"
SVG_FG="${BRAND_DIR}/chirp_logo_foreground.svg"
SVG_NOTIF="${BRAND_DIR}/chirp_notification.svg"
SVG_TRAY_LIGHT="${BRAND_DIR}/chirp_tray_light.svg"
SVG_TRAY_DARK="${BRAND_DIR}/chirp_tray_dark.svg"
SVG_SPLASH="${BRAND_DIR}/chirp_splash.svg"
SVG_SPLASH_DARK="${BRAND_DIR}/chirp_splash_dark.svg"
SVG_OG="${BRAND_DIR}/chirp_og_image.svg"

echo "=== Generating Chirp icons ==="

# ── iOS App Icons ──────────────────────────────────────────────
echo "  iOS app icons..."
IOS_DIR="${PROJECT_DIR}/ios/Runner/Assets.xcassets/AppIcon.appiconset"
rsvg-convert -w 20   -h 20   "$SVG_ICON" > "${IOS_DIR}/Icon-App-20x20@1x.png"
rsvg-convert -w 40   -h 40   "$SVG_ICON" > "${IOS_DIR}/Icon-App-20x20@2x.png"
rsvg-convert -w 60   -h 60   "$SVG_ICON" > "${IOS_DIR}/Icon-App-20x20@3x.png"
rsvg-convert -w 29   -h 29   "$SVG_ICON" > "${IOS_DIR}/Icon-App-29x29@1x.png"
rsvg-convert -w 58   -h 58   "$SVG_ICON" > "${IOS_DIR}/Icon-App-29x29@2x.png"
rsvg-convert -w 87   -h 87   "$SVG_ICON" > "${IOS_DIR}/Icon-App-29x29@3x.png"
rsvg-convert -w 40   -h 40   "$SVG_ICON" > "${IOS_DIR}/Icon-App-40x40@1x.png"
rsvg-convert -w 80   -h 80   "$SVG_ICON" > "${IOS_DIR}/Icon-App-40x40@2x.png"
rsvg-convert -w 120  -h 120  "$SVG_ICON" > "${IOS_DIR}/Icon-App-40x40@3x.png"
rsvg-convert -w 120  -h 120  "$SVG_ICON" > "${IOS_DIR}/Icon-App-60x60@2x.png"
rsvg-convert -w 180  -h 180  "$SVG_ICON" > "${IOS_DIR}/Icon-App-60x60@3x.png"
rsvg-convert -w 76   -h 76   "$SVG_ICON" > "${IOS_DIR}/Icon-App-76x76@1x.png"
rsvg-convert -w 152  -h 152  "$SVG_ICON" > "${IOS_DIR}/Icon-App-76x76@2x.png"
rsvg-convert -w 167  -h 167  "$SVG_ICON" > "${IOS_DIR}/Icon-App-83.5x83.5@2x.png"
rsvg-convert -w 1024 -h 1024 "$SVG_ICON" > "${IOS_DIR}/Icon-App-1024x1024@1x.png"

# ── macOS App Icons ────────────────────────────────────────────
echo "  macOS app icons..."
MAC_DIR="${PROJECT_DIR}/macos/Runner/Assets.xcassets/AppIcon.appiconset"
for SIZE in 16 32 64 128 256 512 1024; do
  rsvg-convert -w "$SIZE" -h "$SIZE" "$SVG_ICON" > "${MAC_DIR}/app_icon_${SIZE}.png"
done

# ── Android Launcher Icons ─────────────────────────────────────
echo "  Android launcher icons..."
ANDROID_RES="${PROJECT_DIR}/android/app/src/main/res"
rsvg-convert -w 48  -h 48  "$SVG_ICON" > "${ANDROID_RES}/mipmap-mdpi/ic_launcher.png"
rsvg-convert -w 72  -h 72  "$SVG_ICON" > "${ANDROID_RES}/mipmap-hdpi/ic_launcher.png"
rsvg-convert -w 96  -h 96  "$SVG_ICON" > "${ANDROID_RES}/mipmap-xhdpi/ic_launcher.png"
rsvg-convert -w 144 -h 144 "$SVG_ICON" > "${ANDROID_RES}/mipmap-xxhdpi/ic_launcher.png"
rsvg-convert -w 192 -h 192 "$SVG_ICON" > "${ANDROID_RES}/mipmap-xxxhdpi/ic_launcher.png"

# ── Android Adaptive Icon Foreground ───────────────────────────
echo "  Android adaptive foreground..."
rsvg-convert -w 108 -h 108 "$SVG_FG" > "${ANDROID_RES}/mipmap-mdpi/ic_launcher_foreground.png"
rsvg-convert -w 162 -h 162 "$SVG_FG" > "${ANDROID_RES}/mipmap-hdpi/ic_launcher_foreground.png"
rsvg-convert -w 216 -h 216 "$SVG_FG" > "${ANDROID_RES}/mipmap-xhdpi/ic_launcher_foreground.png"
rsvg-convert -w 324 -h 324 "$SVG_FG" > "${ANDROID_RES}/mipmap-xxhdpi/ic_launcher_foreground.png"
rsvg-convert -w 432 -h 432 "$SVG_FG" > "${ANDROID_RES}/mipmap-xxxhdpi/ic_launcher_foreground.png"

# ── Android Notification Icon ──────────────────────────────────
echo "  Android notification icons..."
mkdir -p "${ANDROID_RES}/drawable-mdpi" "${ANDROID_RES}/drawable-hdpi" \
         "${ANDROID_RES}/drawable-xhdpi" "${ANDROID_RES}/drawable-xxhdpi" \
         "${ANDROID_RES}/drawable-xxxhdpi"
rsvg-convert -w 24 -h 24 "$SVG_NOTIF" > "${ANDROID_RES}/drawable-mdpi/ic_notification.png"
rsvg-convert -w 36 -h 36 "$SVG_NOTIF" > "${ANDROID_RES}/drawable-hdpi/ic_notification.png"
rsvg-convert -w 48 -h 48 "$SVG_NOTIF" > "${ANDROID_RES}/drawable-xhdpi/ic_notification.png"
rsvg-convert -w 72 -h 72 "$SVG_NOTIF" > "${ANDROID_RES}/drawable-xxhdpi/ic_notification.png"
rsvg-convert -w 96 -h 96 "$SVG_NOTIF" > "${ANDROID_RES}/drawable-xxxhdpi/ic_notification.png"

# ── Windows ICO ────────────────────────────────────────────────
echo "  Windows ICO..."
WIN_DIR="${PROJECT_DIR}/windows/runner/resources"
for SIZE in 16 32 48 64 128 256; do
  rsvg-convert -w "$SIZE" -h "$SIZE" "$SVG_ICON" > "/tmp/chirp_win_${SIZE}.png"
done
magick /tmp/chirp_win_16.png /tmp/chirp_win_32.png /tmp/chirp_win_48.png \
       /tmp/chirp_win_64.png /tmp/chirp_win_128.png /tmp/chirp_win_256.png \
       "${WIN_DIR}/app_icon.ico"
rm -f /tmp/chirp_win_*.png

# ── Linux Icon ─────────────────────────────────────────────────
echo "  Linux icon..."
rsvg-convert -w 512 -h 512 "$SVG_ICON" > "${PROJECT_DIR}/linux/chirp.png"

# ── System Tray Icons ──────────────────────────────────────────
echo "  System tray icons..."
TRAY_DIR="${PROJECT_DIR}/assets/icons"
rsvg-convert -w 22 -h 22 "$SVG_TRAY_LIGHT" > "${TRAY_DIR}/tray_icon.png"
rsvg-convert -w 44 -h 44 "$SVG_TRAY_LIGHT" > "${TRAY_DIR}/tray_icon@2x.png"
rsvg-convert -w 22 -h 22 "$SVG_TRAY_DARK"  > "${TRAY_DIR}/tray_icon_dark.png"
rsvg-convert -w 44 -h 44 "$SVG_TRAY_DARK"  > "${TRAY_DIR}/tray_icon_dark@2x.png"

# ── Browser Extension Icons ────────────────────────────────────
echo "  Browser extension icons..."
EXT_DIR="${PROJECT_DIR}/extension/icons"
rsvg-convert -w 16  -h 16  "$SVG_ICON" > "${EXT_DIR}/icon16.png"
rsvg-convert -w 48  -h 48  "$SVG_ICON" > "${EXT_DIR}/icon48.png"
rsvg-convert -w 128 -h 128 "$SVG_ICON" > "${EXT_DIR}/icon128.png"

# ── Website Assets ─────────────────────────────────────────────
echo "  Website assets..."
WEB_DIR="${PROJECT_DIR}/website/images"
rsvg-convert -w 16  -h 16  "$SVG_ICON" > "${WEB_DIR}/favicon-16x16.png"
rsvg-convert -w 32  -h 32  "$SVG_ICON" > "${WEB_DIR}/favicon-32x32.png"
rsvg-convert -w 180 -h 180 "$SVG_ICON" > "${WEB_DIR}/apple-touch-icon.png"
rsvg-convert -w 192 -h 192 "$SVG_ICON" > "${WEB_DIR}/android-chrome-192x192.png"
rsvg-convert -w 512 -h 512 "$SVG_ICON" > "${WEB_DIR}/android-chrome-512x512.png"
# Favicon ICO (multi-size)
magick "${WEB_DIR}/favicon-16x16.png" "${WEB_DIR}/favicon-32x32.png" "${WEB_DIR}/favicon.ico"
# OG Image
rsvg-convert -w 1200 -h 630 "$SVG_OG" > "${WEB_DIR}/og-image.png"

# ── Splash Screen PNGs ─────────────────────────────────────────
echo "  Splash screen PNGs..."
rsvg-convert -w 480 -h 480 "$SVG_SPLASH"      > "${BRAND_DIR}/chirp_splash_480.png"
rsvg-convert -w 240 -h 240 "$SVG_SPLASH"      > "${BRAND_DIR}/chirp_splash_240.png"
rsvg-convert -w 480 -h 480 "$SVG_SPLASH_DARK" > "${BRAND_DIR}/chirp_splash_480_dark.png"
rsvg-convert -w 240 -h 240 "$SVG_SPLASH_DARK" > "${BRAND_DIR}/chirp_splash_240_dark.png"

# ── Store Assets ───────────────────────────────────────────────
echo "  Store listing assets..."
STORE_DIR="${BRAND_DIR}/store"
mkdir -p "$STORE_DIR"
rsvg-convert -w 512  -h 512 "$SVG_ICON" > "${STORE_DIR}/play_store_icon_512.png"
rsvg-convert -w 300  -h 300 "$SVG_ICON" > "${STORE_DIR}/ms_store_icon_300.png"
rsvg-convert -w 1200 -h 630 "$SVG_OG"   > "${STORE_DIR}/play_feature_graphic.png"

echo "=== All Chirp icons generated successfully ==="
