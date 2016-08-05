#!/bin/sh
set -e

echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

SWIFT_STDLIB_PATH="${DT_TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"

install_framework()
{
  if [ -r "${BUILT_PRODUCTS_DIR}/$1" ]; then
    local source="${BUILT_PRODUCTS_DIR}/$1"
  elif [ -r "${BUILT_PRODUCTS_DIR}/$(basename "$1")" ]; then
    local source="${BUILT_PRODUCTS_DIR}/$(basename "$1")"
  elif [ -r "$1" ]; then
    local source="$1"
  fi

  local destination="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

  if [ -L "${source}" ]; then
      echo "Symlinked..."
      source="$(readlink "${source}")"
  fi

  # use filter instead of exclude so missing patterns dont' throw errors
  echo "rsync -av --filter \"- CVS/\" --filter \"- .svn/\" --filter \"- .git/\" --filter \"- .hg/\" --filter \"- Headers\" --filter \"- PrivateHeaders\" --filter \"- Modules\" \"${source}\" \"${destination}\""
  rsync -av --filter "- CVS/" --filter "- .svn/" --filter "- .git/" --filter "- .hg/" --filter "- Headers" --filter "- PrivateHeaders" --filter "- Modules" "${source}" "${destination}"

  local basename
  basename="$(basename -s .framework "$1")"
  binary="${destination}/${basename}.framework/${basename}"
  if ! [ -r "$binary" ]; then
    binary="${destination}/${basename}"
  fi

  # Strip invalid architectures so "fat" simulator / device frameworks work on device
  if [[ "$(file "$binary")" == *"dynamically linked shared library"* ]]; then
    strip_invalid_archs "$binary"
  fi

  # Resign the code if required by the build settings to avoid unstable apps
  code_sign_if_enabled "${destination}/$(basename "$1")"

  # Embed linked Swift runtime libraries. No longer necessary as of Xcode 7.
  if [ "${XCODE_VERSION_MAJOR}" -lt 7 ]; then
    local swift_runtime_libs
    swift_runtime_libs=$(xcrun otool -LX "$binary" | grep --color=never @rpath/libswift | sed -E s/@rpath\\/\(.+dylib\).*/\\1/g | uniq -u  && exit ${PIPESTATUS[0]})
    for lib in $swift_runtime_libs; do
      echo "rsync -auv \"${SWIFT_STDLIB_PATH}/${lib}\" \"${destination}\""
      rsync -auv "${SWIFT_STDLIB_PATH}/${lib}" "${destination}"
      code_sign_if_enabled "${destination}/${lib}"
    done
  fi
}

# Signs a framework with the provided identity
code_sign_if_enabled() {
  if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}" -a "${CODE_SIGNING_REQUIRED}" != "NO" -a "${CODE_SIGNING_ALLOWED}" != "NO" ]; then
    # Use the current code_sign_identitiy
    echo "Code Signing $1 with Identity ${EXPANDED_CODE_SIGN_IDENTITY_NAME}"
    echo "/usr/bin/codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY} ${OTHER_CODE_SIGN_FLAGS} --preserve-metadata=identifier,entitlements \"$1\""
    /usr/bin/codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY} ${OTHER_CODE_SIGN_FLAGS} --preserve-metadata=identifier,entitlements "$1"
  fi
}

# Strip invalid architectures
strip_invalid_archs() {
  binary="$1"
  # Get architectures for current file
  archs="$(lipo -info "$binary" | rev | cut -d ':' -f1 | rev)"
  stripped=""
  for arch in $archs; do
    if ! [[ "${VALID_ARCHS}" == *"$arch"* ]]; then
      # Strip non-valid architectures in-place
      lipo -remove "$arch" -output "$binary" "$binary" || exit 1
      stripped="$stripped $arch"
    fi
  done
  if [[ "$stripped" ]]; then
    echo "Stripped $binary of architectures:$stripped"
  fi
}


if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_framework "$BUILT_PRODUCTS_DIR/AFNetworking/AFNetworking.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Alamofire/Alamofire.framework"
  install_framework "${PODS_ROOT}/AudioKit/iOS/AudioKit.framework"
  install_framework "$BUILT_PRODUCTS_DIR/BAFluidView/BAFluidView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/BFRadialWaveView/BFRadialWaveView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Bolts/Bolts.framework"
  install_framework "$BUILT_PRODUCTS_DIR/BubbleTransition/BubbleTransition.framework"
  install_framework "$BUILT_PRODUCTS_DIR/CBZSplashView/CBZSplashView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/CircleProgressBar/CircleProgressBar.framework"
  install_framework "$BUILT_PRODUCTS_DIR/ESTMusicIndicator/ESTMusicIndicator.framework"
  install_framework "$BUILT_PRODUCTS_DIR/EZSwipeController/EZSwipeController.framework"
  install_framework "$BUILT_PRODUCTS_DIR/GSKStretchyHeaderView/GSKStretchyHeaderView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Gecco/Gecco.framework"
  install_framework "$BUILT_PRODUCTS_DIR/MEVFloatingButton/MEVFloatingButton.framework"
  install_framework "$BUILT_PRODUCTS_DIR/MGSwipeTableCell/MGSwipeTableCell.framework"
  install_framework "$BUILT_PRODUCTS_DIR/MNFloatingActionButton/MNFloatingActionButton.framework"
  install_framework "$BUILT_PRODUCTS_DIR/MarqueeLabel/MarqueeLabel.framework"
  install_framework "$BUILT_PRODUCTS_DIR/NVActivityIndicatorView/NVActivityIndicatorView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Onboard/Onboard.framework"
  install_framework "$BUILT_PRODUCTS_DIR/PageMenu/PageMenu.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Pages/Pages.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Parse/Parse.framework"
  install_framework "$BUILT_PRODUCTS_DIR/ParseUI/ParseUI.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Shimmer/Shimmer.framework"
  install_framework "$BUILT_PRODUCTS_DIR/StretchHeader/StretchHeader.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SwiftSiriWaveformView/SwiftSiriWaveformView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Toast-Swift/Toast_Swift.framework"
  install_framework "$BUILT_PRODUCTS_DIR/UIColor+BFPaperColors/UIColor_BFPaperColors.framework"
  install_framework "$BUILT_PRODUCTS_DIR/VideoSplashKit/VideoSplashKit.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Whisper/Whisper.framework"
  install_framework "$BUILT_PRODUCTS_DIR/XLPagerTabStrip/XLPagerTabStrip.framework"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_framework "$BUILT_PRODUCTS_DIR/AFNetworking/AFNetworking.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Alamofire/Alamofire.framework"
  install_framework "${PODS_ROOT}/AudioKit/iOS/AudioKit.framework"
  install_framework "$BUILT_PRODUCTS_DIR/BAFluidView/BAFluidView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/BFRadialWaveView/BFRadialWaveView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Bolts/Bolts.framework"
  install_framework "$BUILT_PRODUCTS_DIR/BubbleTransition/BubbleTransition.framework"
  install_framework "$BUILT_PRODUCTS_DIR/CBZSplashView/CBZSplashView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/CircleProgressBar/CircleProgressBar.framework"
  install_framework "$BUILT_PRODUCTS_DIR/ESTMusicIndicator/ESTMusicIndicator.framework"
  install_framework "$BUILT_PRODUCTS_DIR/EZSwipeController/EZSwipeController.framework"
  install_framework "$BUILT_PRODUCTS_DIR/GSKStretchyHeaderView/GSKStretchyHeaderView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Gecco/Gecco.framework"
  install_framework "$BUILT_PRODUCTS_DIR/MEVFloatingButton/MEVFloatingButton.framework"
  install_framework "$BUILT_PRODUCTS_DIR/MGSwipeTableCell/MGSwipeTableCell.framework"
  install_framework "$BUILT_PRODUCTS_DIR/MNFloatingActionButton/MNFloatingActionButton.framework"
  install_framework "$BUILT_PRODUCTS_DIR/MarqueeLabel/MarqueeLabel.framework"
  install_framework "$BUILT_PRODUCTS_DIR/NVActivityIndicatorView/NVActivityIndicatorView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Onboard/Onboard.framework"
  install_framework "$BUILT_PRODUCTS_DIR/PageMenu/PageMenu.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Pages/Pages.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Parse/Parse.framework"
  install_framework "$BUILT_PRODUCTS_DIR/ParseUI/ParseUI.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Shimmer/Shimmer.framework"
  install_framework "$BUILT_PRODUCTS_DIR/StretchHeader/StretchHeader.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SwiftSiriWaveformView/SwiftSiriWaveformView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Toast-Swift/Toast_Swift.framework"
  install_framework "$BUILT_PRODUCTS_DIR/UIColor+BFPaperColors/UIColor_BFPaperColors.framework"
  install_framework "$BUILT_PRODUCTS_DIR/VideoSplashKit/VideoSplashKit.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Whisper/Whisper.framework"
  install_framework "$BUILT_PRODUCTS_DIR/XLPagerTabStrip/XLPagerTabStrip.framework"
fi
