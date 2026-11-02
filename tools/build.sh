#!/usr/bin/env bash
# Checks, builds, and tests Pairwise.
#
# Usage: tools/build.sh [command...]
#   check       Formatting (swift-format), lint (SwiftLint), dependency rules, shellcheck.
#   format      Rewrite Swift code with SwiftLint --fix and swift-format (the only
#               command that changes code).
#   test        Package tests (swift test). Followed by a filter, only matching tests:
#               tools/build.sh test DragGripTests
#   coverage    Package tests with code coverage; fails when a module is below its
#               line-coverage target (Core 90 %, WindowSystem 75 %, UI 70 %; PLAN.md, Test plan).
#   build       Build the macOS app with its tests (compiled, not run), Debug.
#   release     Build the macOS app, Release, and fail if test code is in it (ADR 0050).
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
# CI has no certificate and nothing there needs the Accessibility permission (ADR 0012).
CI_SIGNING=()
[[ "${CI:-}" == true ]] && CI_SIGNING=(CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=)
COMMANDS=" check format test coverage build apptest run quick verify ci clean help "
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
  has shellcheck || fail "shellcheck not found. Run tools/setup.sh."
  shellcheck -x "$TOOLS_DIR"/*.sh "$TOOLS_DIR"/xcode/*.sh "$TOOLS_DIR"/git-hooks/* || fail "shellcheck reported problems"
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
  # the line count and the missed lines. The stress test drives real windows and
  # is not code that runs for users (ADR 0031).
  (cd "$PACKAGE_DIR" && xcrun llvm-cov report -instr-profile "$debug/codecov/default.profdata" \
    "${binaries[0]}" "${others[@]}") |
    awk -v prefix="Sources/$1/" 'index($1, prefix) == 1 && !index($1, "DragStressTest") { lines += $8; missed += $9 }
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
  grep -E 'DragStressTest|AnimatedTestView|SCRecordingOutput|--record|--seam-look|--seam-test|--join-test|--drag-stress-test' \
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
