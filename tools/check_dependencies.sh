#!/usr/bin/env bash
# Verifies the import rules of ADR 0001 that Package.swift cannot express:
#   - PairwiseCore imports only Foundation (no UI frameworks, no other module).
#   - PairwiseWindowSystem imports neither SwiftUI nor PairwiseUI.
#   - The Accessibility API, event taps and ScreenCaptureKit appear only in PairwiseWindowSystem,
#     the one place that touches another app's windows.
#   - Test code that drives or records the screen is only in debug builds (ADR 0050).
# Package.swift already enforces the dependency direction between the modules.
set -euo pipefail
# shellcheck source=tools/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SOURCES="$PACKAGE_DIR/Sources"
WINDOW_SYSTEM_FORBIDDEN='SwiftUI|UIKit|PairwiseUI'
WINDOW_SYSTEM_ONLY='AXUIElement|AXObserver|CGEvent\.tapCreate|ScreenCaptureKit|SCScreenshotManager'

# Prints "file:line: import" for every import in the Swift files under [1].
imports_in() {
  [[ -d "$1" ]] || return 0
  grep -rnE --include='*.swift' '^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]' "$1" || true
}

# Prints the imports under [1] whose module matches the regex [2], relative to ROOT_DIR.
violations() {
  imports_in "$1" | grep -E "import[[:space:]]+(class |struct |enum |protocol |func |var )?($2)([.[:space:]]|$)" |
    sed "s|^$ROOT_DIR/||" || true
}

found=0
report() {
  local rule="$1" lines="$2"
  [[ -n "$lines" ]] || return 0
  printf '%s:\n%s\n' "$rule" "$lines" >&2
  found=1
}

if [[ ! -d "$SOURCES" ]]; then
  info "No Packages/PairwiseKit/Sources yet; dependency check skipped"
  exit 0
fi

core_non_foundation="$(imports_in "$SOURCES/PairwiseCore" |
  grep -vE 'import[[:space:]]+Foundation([.[:space:]]|$)' | sed "s|^$ROOT_DIR/||" || true)"
report "PairwiseCore may import only Foundation" "$core_non_foundation"
report "PairwiseWindowSystem may not import SwiftUI, UIKit or PairwiseUI" \
  "$(violations "$SOURCES/PairwiseWindowSystem" "$WINDOW_SYSTEM_FORBIDDEN")"

outside="$(grep -rnE --include='*.swift' "$WINDOW_SYSTEM_ONLY" "$SOURCES" "$ROOT_DIR/Apps" 2>/dev/null |
  grep -v "$SOURCES/PairwiseWindowSystem/" | sed "s|^$ROOT_DIR/||" || true)"
report "Only PairwiseWindowSystem may use the Accessibility API, event taps or ScreenCaptureKit" "$outside"

# Code that drives or records the screen stays out of a release build (ADR 0050).
debug_only=""
for file in "$SOURCES"/PairwiseWindowSystem/DragStressTest*.swift \
  "$SOURCES/PairwiseWindowSystem/ScreenRecording.swift" "$SOURCES/PairwiseWindowSystem/FrameDump.swift" "$ROOT_DIR/Apps/PairwiseMac/AnimatedTestView.swift"; do
  [[ "$(head -n 1 "$file")" == "#if DEBUG" ]] || debug_only+="${file#"$ROOT_DIR"/}"$'\n'
done
report "Test code must start with #if DEBUG (ADR 0050)" "$debug_only"

((found == 0)) || exit 1
