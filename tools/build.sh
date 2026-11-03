#!/usr/bin/env bash
# Checks, builds, and tests Pairwise.
#
# Usage: tools/build.sh [command...]
#   check       Formatting (swift-format), lint (SwiftLint), dependency rules, shell scripts
#               (shellcheck), translations.
#   format      Rewrite Swift code with SwiftLint --fix and swift-format (the only
#               command that changes code).
#   test        Package tests (swift test). Followed by a filter, only matching tests:
#               tools/build.sh test DragGripTests
#   coverage    Package tests with code coverage; fails when a module is below its
#               line-coverage target (Core 90 %, WindowSystem 75 %, UI 70 %; PLAN.md, Test plan).
#   build       Build the macOS app with its tests (compiled, not run), Debug.
#   release     Build the macOS app, Release, and fail if test code is in it (ADR 0050).
#   export      Archive the macOS app and export it with the Developer ID to build/PairwiseMac/;
#               not notarized (ADR 0056).
#   package     A release: export, notarize with the keychain profile pairwise-notary, staple
#               and check, then build/release/Pairwise-<version>-<build>.zip and a notarized
#               .dmg beside it (ADR 0056). Needs the owner's certificate and profile.
#   publish     A release from this Mac (ADR 0058): checks that the tree is clean, that the
#               tag v<version> points at HEAD and that origin/main holds it, runs package,
#               then tools/publish.sh. It publishes, so the owner runs it.
#   publish-page  Only the website (ADR 0065): sends tools/site to gh-pages, without a release.
#               It publishes, so the owner runs it.
#   screenshots The website's pictures (ADR 0065): runs the scenes on TextEdit and Preview and
#               writes tools/site/shots/ as WebP, for you to judge with git. Takes the screen and pointer.
#   apptest     The macOS app's tests, including the XCUITest smoke tests. Followed by
#               a filter, only those tests, as Class or Class/testName, several
#               separated by commas: tools/build.sh apptest LaunchTests/testShowsWindow
#   run         Build the macOS app and start it. Every word after run goes to the app.
#   quick       check + test: the gate for a step that leaves the app alone.
#   verify      check + test + build: the gate for a change to the app. Leaves the
#               screen alone (ADR 0011).
#   ci          check + test + build + apptest: when the owner says the UI tests may
#               take the screen, before a push and at the end of a plan. The default.
#   clean       Remove build/.
#
# Commands run in the order given. The script stops at the first failure and
# exits non-zero, so it can gate commits and CI. Output goes to build/logs/,
# build/reports/ and build/DerivedData/; nothing is written loose in build/.

set -euo pipefail

# macOS ships bash 3.2; this script needs bash 4.4+ (mapfile, empty arrays under set -u).
if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
  for candidate in /opt/homebrew/bin/bash /usr/local/bin/bash; do
    [[ -x "$candidate" ]] && exec "$candidate" "$0" "$@"
  done
  echo "bash 4.4 or newer is required. Run tools/setup.sh (installs it via Homebrew)." >&2
  exit 1
fi

# shellcheck source=tools/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SWIFT_DIRS=(Packages Apps UITests)
# Warnings fail the package build here, not in Package.swift: Xcode adds
# -suppress-warnings to package dependencies, which clashes with -warnings-as-errors.
SWIFT_TEST_FLAGS=(-Xswiftc -warnings-as-errors)
DERIVED_DATA="$BUILD_DIR/DerivedData"
LOG_DIR="$BUILD_DIR/logs"
REPORT_DIR="$BUILD_DIR/reports"
MAC_DESTINATION="platform=macOS,arch=$(uname -m)"
EXPORT_OPTIONS="$TOOLS_DIR/ExportOptions-mac.plist"
# The certificate that signs a release, and the notary keychain profile (ADR 0056).
SIGNING_CERTIFICATE="Developer ID Application"
NOTARY_PROFILE="pairwise-notary"
# CI has no certificate and nothing there needs the Accessibility permission (ADR 0012).
CI_SIGNING=()
[[ "${CI:-}" == true ]] && CI_SIGNING=(CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=)
COMMANDS=" check format test coverage build release export package publish publish-page screenshots apptest run quick verify ci clean help "
# The width of a picture on the website, twice what the page shows, for sharp text.
SCREENSHOT_MAX_WIDTH=1800
# The quality of the website's pictures, where lost detail does not show in text yet.
SCREENSHOT_QUALITY=90
declare -a SUMMARY=()

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; }

require_package() {
  [[ -f "$PACKAGE_DIR/Package.swift" ]] \
    || fail "No Packages/PairwiseKit/Package.swift; it is part of M0 (docs/plans/M0-skeleton-ci.md)."
}

require_project() {
  [[ -d "$XCODE_PROJECT" ]] \
    || fail "No Pairwise.xcodeproj; it is part of M0 (docs/plans/M0-skeleton-ci.md)."
}

swift_format() {
  local exe
  exe="$(xcrun --find swift-format 2>/dev/null)" || fail "swift-format not found. Run tools/setup.sh."
  "$exe" "$@"
}

# Prints the existing directories from SWIFT_DIRS that hold Swift files, relative to ROOT_DIR.
swift_dirs() {
  local d
  for d in "${SWIFT_DIRS[@]}"; do
    [[ -d "$ROOT_DIR/$d" ]] && find "$ROOT_DIR/$d" -name '*.swift' -print -quit | grep -q . && echo "$d"
  done
  return 0
}

timed() {
  local name="$1"; shift
  local start=$SECONDS
  "$@"
  SUMMARY+=("$(printf '%-12s %4ds' "$name" $((SECONDS - start)))")
}

# Runs xcodebuild on the project with the shared DerivedData, logging to build/logs/[1].log.
# Output is shown through xcbeautify when it is installed.
# Post: fails the build with the log's tail when xcodebuild fails.
xcode() {
  local log="$LOG_DIR/$1.log"; shift
  mkdir -p "$LOG_DIR"
  local rc=0
  if has xcbeautify; then
    (cd "$ROOT_DIR" && xcodebuild -project "$XCODE_PROJECT" -derivedDataPath "$DERIVED_DATA" "${CI_SIGNING[@]}" "$@" 2>&1) |
      tee "$log" | xcbeautify --quiet || rc=${PIPESTATUS[0]}
  else
    (cd "$ROOT_DIR" && xcodebuild -project "$XCODE_PROJECT" -derivedDataPath "$DERIVED_DATA" "${CI_SIGNING[@]}" "$@" >"$log" 2>&1) \
      || rc=$?
  fi
  ((rc == 0)) || { tail -n 30 "$log" >&2; fail "xcodebuild failed; log: ${log#"$ROOT_DIR"/}"; }
}

# Prints a fresh result bundle path under build/reports/ for [1]; xcodebuild refuses an existing one.
result_bundle() {
  local path="$REPORT_DIR/$1.xcresult"
  mkdir -p "$REPORT_DIR"
  rm -rf "$path"
  echo "$path"
}

cmd_format() {
  step "Format"
  local dirs; mapfile -t dirs < <(swift_dirs)
  ((${#dirs[@]} > 0)) || { info "No Swift files yet"; return; }
  has swiftlint || fail "swiftlint not found. Run tools/setup.sh."
  (cd "$ROOT_DIR" && swiftlint lint --fix --quiet)
  (cd "$ROOT_DIR" && swift_format format --in-place --recursive --parallel "${dirs[@]}")
  ok "Formatted"
}

cmd_check() {
  step "Check"
  local dirs; mapfile -t dirs < <(swift_dirs)
  if ((${#dirs[@]} > 0)); then
    (cd "$ROOT_DIR" && swift_format lint --strict --recursive --parallel "${dirs[@]}") \
      || fail "swift-format reported problems. Run: tools/build.sh format"
    ok "swift-format"
    has swiftlint || fail "swiftlint not found. Run tools/setup.sh."
    (cd "$ROOT_DIR" && swiftlint lint --strict --quiet) \
      || fail "SwiftLint reported problems (.swiftlint.yml, ADR 0005)"
    ok "SwiftLint"
  else
    info "No Swift files yet; swift-format and SwiftLint skipped"
  fi
  "$TOOLS_DIR/check_dependencies.sh" || fail "Dependency rules violated (ADR 0001)"
  ok "Dependency rules"
  python3 "$TOOLS_DIR/i18n/translate.py" check || fail "Translations are incomplete (ADR 0010, tools/i18n)"
  ok "Translations"
  has shellcheck || fail "shellcheck not found. Run tools/setup.sh."
  shellcheck -x "$TOOLS_DIR"/*.sh "$TOOLS_DIR"/homebrew/*.sh "$TOOLS_DIR"/xcode/*.sh "$TOOLS_DIR"/git-hooks/* || fail "shellcheck reported problems"
  ok "shellcheck"
}

# Runs the package tests; an optional filter narrows them to matching suites or tests.
cmd_test() {
  local filter="${1:-}"
  step "Package tests${filter:+ ($filter)}"
  require_package
  mkdir -p "$LOG_DIR"
  local args=(test --package-path "$PACKAGE_DIR" "${SWIFT_TEST_FLAGS[@]}")
  [[ -n "$filter" ]] && args+=(--filter "$filter")
  local rc=0 log="$LOG_DIR/test.log"
  swift "${args[@]}" >"$log" 2>&1 || rc=$?
  if ((rc != 0)); then
    grep -E "✘|error:" "$log" | head -n 40 >&2 || tail -n 40 "$log" >&2
    fail "Package tests failed; log: build/logs/test.log"
  fi
  # One summary line per test bundle; the full output stays in the log.
  grep -E "^✔ Test run with" "$log" | sed "s/^✔ /    /" || true
  ok "Package tests passed"
}

# Line-coverage target per package module, in percent (PLAN.md, Test plan).
declare -A COVERAGE_TARGETS=([PairwiseCore]=90 [PairwiseWindowSystem]=75 [PairwiseUI]=70)

# Prints the line coverage, in percent, of the package sources of module [1],
# from the last coverage run; "100.00" for a module without executable lines.
line_coverage() {
  local debug="$PACKAGE_DIR/.build/debug" binaries=() bundle
  for bundle in "$debug"/*.xctest; do
    binaries+=("$bundle/Contents/MacOS/$(basename "$bundle" .xctest)")
  done
  ((${#binaries[@]} > 0)) || return 0
  local others=() binary
  for binary in "${binaries[@]:1}"; do others+=(-object "$binary"); done
  # llvm-cov records file names relative to the package; columns 8 and 9 are
  # the line count and the missed lines. The stress test drives real windows, and it and
  # the debug tools are not code that runs for users (ADR 0031, 0050).
  (cd "$PACKAGE_DIR" && xcrun llvm-cov report -instr-profile "$debug/codecov/default.profdata" \
    "${binaries[0]}" "${others[@]}") |
    awk -v prefix="Sources/$1/" 'index($1, prefix) == 1 && !index($1, "DragStressTest") && !index($1, "ScreenRecording") && !index($1, "FrameDump") { lines += $8; missed += $9 }
      END { printf "%.2f\n", lines ? 100 * (lines - missed) / lines : 100 }'
}

cmd_coverage() {
  step "Coverage"
  require_package
  mkdir -p "$LOG_DIR"
  local rc=0
  swift test --package-path "$PACKAGE_DIR" "${SWIFT_TEST_FLAGS[@]}" --enable-code-coverage \
    >"$LOG_DIR/coverage.log" 2>&1 || rc=$?
  ((rc == 0)) || { tail -n 30 "$LOG_DIR/coverage.log" >&2; fail "Package tests failed; log: build/logs/coverage.log"; }
  local module percent below=0
  for module in "${!COVERAGE_TARGETS[@]}"; do
    percent="$(line_coverage "$module")"
    [[ -n "$percent" ]] || fail "No coverage data for $module"
    if awk -v p="$percent" -v t="${COVERAGE_TARGETS[$module]}" 'BEGIN { exit !(p >= t) }'; then
      ok "$module $percent % (target ${COVERAGE_TARGETS[$module]} %)"
    else
      warn "$module $percent % is below its target of ${COVERAGE_TARGETS[$module]} %"
      below=1
    fi
  done
  ((below == 0)) || fail "Coverage below target"
}

cmd_build() {
  step "Build"
  require_project
  # build-for-testing also compiles the UI tests, without taking the screen (ADR 0011).
  xcode build-mac -scheme "$MAC_SCHEME" -destination "$MAC_DESTINATION" build-for-testing
  ok "$MAC_SCHEME"
}

# Prints the marks of test code that the binary [1] holds (ADR 0050). Read into a variable first:
# a grep that stops at its first match would fail the pipeline, and so seem to find nothing.
test_code_in() {
  local text
  text="$(strings "$1")"
  grep -E 'DragStressTest|AnimatedTestView|SCRecordingOutput|--record|--seam-look|--seam-test|--join-test|--drag-stress-test|--dump-frames|--kill-test|--kill-check|--settings-look' \
    <<<"$text" | sort -u | head -n 5 || true
}

cmd_release() {
  step "Release"
  require_project
  xcode build-release -scheme "$MAC_SCHEME" -destination "$MAC_DESTINATION" -configuration Release build
  local binary="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app/Contents/MacOS/$APP_NAME"
  [[ -f "$binary" ]] || fail "No release app at ${binary#"$ROOT_DIR"/}"
  local found
  found="$(test_code_in "$binary")"
  [[ -z "$found" ]] || fail "Test code is in the release build (ADR 0050): $found"
  ok "No test code in the release build"
}

require_signing() {
  security find-identity -v -p codesigning | grep -q "\"$SIGNING_CERTIFICATE: " \
    || fail "No \"$SIGNING_CERTIFICATE\" certificate in the keychain (ADR 0056)."
}

require_notary_profile() {
  xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1 \
    || fail "No notary profile. Make it once: xcrun notarytool store-credentials $NOTARY_PROFILE"
}

# Archives the app in Release and exports it signed with the Developer ID into [1].
export_mac() {
  local out="$1" archive="$BUILD_DIR/archives/$MAC_SCHEME.xcarchive"
  rm -rf "$out" "$archive"
  xcode archive -scheme "$MAC_SCHEME" -configuration Release -destination "generic/platform=macOS" \
    -archivePath "$archive" archive
  xcodebuild -exportArchive -archivePath "$archive" -exportPath "$out" \
    -exportOptionsPlist "$EXPORT_OPTIONS" >"$LOG_DIR/export.log" 2>&1 \
    || { tail -n 30 "$LOG_DIR/export.log" >&2; fail "Export failed; log: build/logs/export.log"; }
  [[ -d "$out/$APP_NAME.app" ]] || fail "No $APP_NAME.app in ${out#"$ROOT_DIR"/}"
}

# Fails unless the app's signature holds, it has the hardened runtime and it holds no test code.
# The app need not be notarized yet.
verify_signature() {
  local app="$1" found details
  codesign --verify --deep --strict "$app" 2>"$LOG_DIR/codesign.log" \
    || fail "The signature does not verify; log: build/logs/codesign.log"
  details="$(codesign --display --verbose=2 "$app" 2>&1)"
  grep -q "^Authority=$SIGNING_CERTIFICATE: " <<<"$details" || fail "Not signed with the Developer ID"
  grep -q "flags=.*runtime" <<<"$details" || fail "The hardened runtime is off"
  found="$(test_code_in "$app/Contents/MacOS/$APP_NAME")"
  [[ -z "$found" ]] || fail "Test code is in the release build (ADR 0050): $found"
  ok "Signed with the Developer ID, hardened, no test code"
}

cmd_export() {
  step "Export"
  require_project
  require_signing
  mkdir -p "$LOG_DIR"
  export_mac "$BUILD_DIR/$MAC_SCHEME"
  verify_signature "$BUILD_DIR/$MAC_SCHEME/$APP_NAME.app"
  ok "$MAC_SCHEME -> build/$MAC_SCHEME"
}

# Sends a zip or disk image to Apple's notary service and waits for its verdict;
# a rejection saves the service's log.
notarize_file() {
  local file="$1" name status id result
  name="$(basename "$file")"
  result="$LOG_DIR/notarize-$name.json"
  info "Waiting for Apple's notary service ($name)"
  xcrun notarytool submit "$file" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json >"$result" \
    || { cat "$result" >&2; fail "Could not submit $name for notarization."; }
  status="$(plutil -extract status raw "$result")"
  id="$(plutil -extract id raw "$result")"
  if [[ "$status" != Accepted ]]; then
    xcrun notarytool log "$id" --keychain-profile "$NOTARY_PROFILE" "$LOG_DIR/notarize-$name-log.json" \
      >/dev/null 2>&1 || true
    fail "Notarization of $name: $status; log: build/logs/notarize-$name-log.json"
  fi
  ok "Notarized $name"
}

# Staples the notary's ticket to an app or a disk image, so it opens offline too.
staple() {
  xcrun stapler staple "$1" >"$LOG_DIR/staple.log" 2>&1 \
    || fail "Could not staple the ticket to $(basename "$1"); log: build/logs/staple.log"
}

# Builds the disk image people install from: the stapled app and a link to
# Applications on the rendered background, signed with the Developer ID.
make_disk_image() {
  local app="$1" out="$2" work="$BUILD_DIR/dmg" scale
  rm -rf "$work"
  mkdir -p "$work"
  ensure_dmgbuild
  for scale in 1 2; do
    swift "$TOOLS_DIR/dmg/render.swift" "$TOOLS_DIR/dmg/background.svg" "$work/background@${scale}x.png" "$scale" \
      || fail "Could not render the disk image background"
  done
  tiffutil -cathidpicheck "$work/background@1x.png" "$work/background@2x.png" -out "$work/background.tiff" \
    >/dev/null 2>&1 || fail "Could not combine the background images"
  "$DMGBUILD" -s "$TOOLS_DIR/dmg/settings.py" -D app="$app" -D background="$work/background.tiff" \
    "$APP_NAME" "$out" >"$LOG_DIR/dmgbuild.log" 2>&1 \
    || fail "dmgbuild failed; log: build/logs/dmgbuild.log"
  codesign --sign "$SIGNING_CERTIFICATE" --timestamp "$out" 2>"$LOG_DIR/codesign-dmg.log" \
    || fail "Could not sign the disk image; log: build/logs/codesign-dmg.log"
}

cmd_package() {
  step "Package"
  require_project
  require_signing
  require_notary_profile
  local exported="$BUILD_DIR/$MAC_SCHEME" app="$BUILD_DIR/$MAC_SCHEME/$APP_NAME.app"
  local upload="$BUILD_DIR/release/$APP_NAME-notarize.zip" version build base
  rm -rf "$BUILD_DIR/release"
  mkdir -p "$BUILD_DIR/release" "$LOG_DIR"
  export_mac "$exported"
  verify_signature "$app"
  ditto -c -k --keepParent "$app" "$upload"
  notarize_file "$upload"
  rm -f "$upload"
  staple "$app"
  spctl --assess --type exec "$app" 2>"$LOG_DIR/spctl.log" \
    || fail "Gatekeeper rejects the app; log: build/logs/spctl.log"
  ok "Gatekeeper accepts $APP_NAME.app"
  version="$(defaults read "$app/Contents/Info" CFBundleShortVersionString)"
  build="$(defaults read "$app/Contents/Info" CFBundleVersion)"
  base="$BUILD_DIR/release/$APP_NAME-$version-$build"
  ditto -c -k --keepParent "$app" "$base.zip"
  make_disk_image "$app" "$base.dmg"
  notarize_file "$base.dmg"
  staple "$base.dmg"
  spctl --assess --type open --context context:primary-signature "$base.dmg" 2>"$LOG_DIR/spctl-dmg.log" \
    || fail "Gatekeeper rejects the disk image; log: build/logs/spctl-dmg.log"
  ok "$APP_NAME $version ($build) -> ${base#"$ROOT_DIR"/}.zip and .dmg"
}

# What is published is exactly the source that is public under its tag (ADR 0058).
cmd_publish() {
  step "Publish checks"
  require_project
  local version tag head
  [[ -z "$(git -C "$ROOT_DIR" status --porcelain)" ]] || fail "The working tree has changes; commit them first."
  version="$(grep -o 'MARKETING_VERSION = [^;]*' "$XCODE_PROJECT/project.pbxproj" | sort -u | sed 's/MARKETING_VERSION = //')"
  tag="v$version"
  head="$(git -C "$ROOT_DIR" rev-parse HEAD)"
  git -C "$ROOT_DIR" rev-parse --quiet --verify "$tag^{commit}" >/dev/null \
    || fail "No tag $tag; tag the release first: git tag $tag"
  [[ "$(git -C "$ROOT_DIR" rev-parse "$tag^{commit}")" == "$head" ]] || fail "The tag $tag does not point at HEAD."
  git -C "$ROOT_DIR" fetch --quiet origin main
  [[ "$(git -C "$ROOT_DIR" rev-parse origin/main)" == "$head" ]] || fail "origin/main is not at HEAD; push first."
  "$TOOLS_DIR/release_notes.sh" "$version" >/dev/null
  ok "$APP_NAME $version, tag $tag at HEAD"
  cmd_package
  "$TOOLS_DIR/publish.sh"
}

cmd_apptest() {
  local filter="${1:-}" only=() tests=() test
  step "macOS app tests${filter:+ ($filter)}"
  require_project
  local bundle; bundle="$(result_bundle "$MAC_SCHEME")"
  IFS=, read -ra tests <<<"$filter"
  for test in "${tests[@]}"; do only+=(-only-testing:"PairwiseMacUITests/$test"); done
  xcode apptest -scheme "$MAC_SCHEME" -destination "$MAC_DESTINATION" -resultBundlePath "$bundle" \
    "${only[@]}" test
  ok "$MAC_SCHEME tests passed. Results: ${bundle#"$ROOT_DIR"/}"
}

cmd_run() {
  step "Run"
  require_project
  xcode build-mac -scheme "$MAC_SCHEME" -destination "$MAC_DESTINATION" build
  local app
  app="$(find "$DERIVED_DATA/Build/Products/Debug" -maxdepth 1 -name "$APP_NAME.app" -print -quit 2>/dev/null)"
  [[ -n "$app" ]] || fail "No $APP_NAME.app in build/DerivedData/Build/Products/Debug"
  # open only brings a running copy forward, which would hide the build just made.
  if pgrep -x "$APP_NAME" >/dev/null; then
    fail "$APP_NAME is already running. Quit it, then run this again."
  fi
  info "Starting ${app#"$ROOT_DIR"/}"
  # Launch Services makes the app responsible for itself. Started from the shell,
  # macOS asks for permissions on behalf of the terminal instead (ADR 0012).
  open -W "$app" --args "$@"
}

# Makes the pictures in build/screenshots, and copies them to the website only when every
# scene succeeded (ADR 0065).
cmd_screenshots() {
  local dir="$BUILD_DIR/screenshots" shots="$TOOLS_DIR/site/shots" report name width
  report="$dir/report.txt"
  has cwebp || fail "cwebp not found. Run tools/setup.sh."
  rm -rf "$dir"
  mkdir -p "$dir" "$shots"
  cp "$TOOLS_DIR/screenshots/Travel notes.rtf" "$dir/"
  python3 -I "$TOOLS_DIR/screenshots/make_landscape.py" "$dir/Coast.png"
  cmd_run --screenshots "$report" --settings-tab 1
  [[ -f "$report" ]] || fail "The run left no report. Is the screen unlocked?"
  cat "$report"
  [[ "$(tail -n 1 "$report")" == "screenshots done" ]] || fail "The run did not make every picture."
  for name in join pair drag settings; do
    width="$(sips -g pixelWidth "$dir/$name.png" | awk '/pixelWidth/ { print $2 }')"
    ((width > SCREENSHOT_MAX_WIDTH)) && sips --resampleWidth "$SCREENSHOT_MAX_WIDTH" "$dir/$name.png" >/dev/null
    cwebp -quiet -q "$SCREENSHOT_QUALITY" "$dir/$name.png" -o "$shots/$name.webp"
  done
  ok "The pictures are in ${shots#"$ROOT_DIR"/}. See what changed with git, then commit what you want."
}

cmd_clean() {
  step "Clean"
  rm -rf "${BUILD_DIR:?}"
  ok "Removed build/"
}

run_command() {
  case "$1" in
    check) timed check cmd_check ;;
    format) timed format cmd_format ;;
    test) timed test cmd_test "${2:-}" ;;
    coverage) timed coverage cmd_coverage ;;
    build) timed build cmd_build ;;
    release) timed release cmd_release ;;
    export) timed export cmd_export ;;
    package) timed package cmd_package ;;
    publish) timed publish cmd_publish ;;
    publish-page) timed publish-page "$TOOLS_DIR/publish.sh" --page ;;
    screenshots) timed screenshots cmd_screenshots ;;
    apptest) timed apptest cmd_apptest "${2:-}" ;;
    clean) timed clean cmd_clean ;;
    quick) run_command check; run_command test ;;
    verify) run_command check; run_command test; run_command build ;;
    ci) run_command verify; run_command release; run_command apptest ;;
    -h|--help|help) usage; exit 0 ;;
    *) usage; fail "Unknown command: $1" ;;
  esac
}

(($# == 0)) && set -- ci
while (($#)); do
  c="$1"; shift
  if [[ "$c" == run ]]; then
    cmd_run "$@"
    exit 0
  elif [[ ( "$c" == test || "$c" == apptest ) && -n "${1:-}" && "$COMMANDS" != *" $1 "* ]]; then
    # test and apptest take an optional filter as their next word, unless that
    # word is a command.
    run_command "$c" "$1"; shift
  else
    run_command "$c"
  fi
done

step "Summary"
for line in "${SUMMARY[@]}"; do info "$line"; done
ok "Build succeeded"
