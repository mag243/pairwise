#!/usr/bin/env bash
# Publishes the release that tools/build.sh package left in build/release/
# (ADR 0058): signs the zip into the Sparkle feed, creates the GitHub Release,
# pushes the feed to the branch gh-pages, and writes the Homebrew cask (ADR 0059).
#
# Usage: tools/publish.sh [--dry-run]
#   --dry-run   Sign and write the feed under build/publish/, and stop before
#               anything leaves this Mac.
#
# Signs with the Sparkle key in the keychain, under the account pairwise (ADR 0057).
# It pushes to public repositories, so only the owner runs it.
set -euo pipefail
# shellcheck source=tools/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

REPOSITORY="mag243/pairwise"
TAP_REPOSITORY="mag243/homebrew-tap"
FEED_BRANCH="gh-pages"
SPARKLE_ACCOUNT="pairwise"
MAXIMUM_VERSIONS_IN_FEED=10
WORK="$BUILD_DIR/publish"

dry_run=0
[[ "${1:-}" == --dry-run ]] && dry_run=1

# The one file in build/release/ with the extension [1].
release_file() {
  local files=("$BUILD_DIR"/release/*."$1")
  [[ ${#files[@]} == 1 && -f "${files[0]}" ]] \
    || fail "Expected one .$1 in build/release/; run tools/build.sh package first."
  printf '%s\n' "${files[0]}"
}

# Clones the feed's branch into [1], or starts it when this is the first release.
clone_feed() {
  local clone="$1" url="https://github.com/$REPOSITORY.git"
  if git ls-remote --exit-code --heads "$url" "$FEED_BRANCH" >/dev/null; then
    git clone --quiet --depth 1 --branch "$FEED_BRANCH" "$url" "$clone"
  else
    git init --quiet --initial-branch "$FEED_BRANCH" "$clone"
    git -C "$clone" remote add origin "$url"
    # Pages serves the files as they are, without building a site from them.
    touch "$clone/.nojekyll"
  fi
}

# Adds the zip to the feed in the clone [4]. generate_appcast reuses the feed it finds
# next to the zip, and the notes with the zip's name become the new item's notes.
update_feed() {
  local zip="$1" tag="$2" notes="$3" clone="$4" feed="$WORK/feed" tool
  mkdir -p "$feed"
  cp "$zip" "$feed/"
  cp "$notes" "$feed/$(basename "$zip" .zip).md"
  [[ -f "$clone/appcast.xml" ]] && cp "$clone/appcast.xml" "$feed/"
  tool="$(find "$BUILD_DIR/DerivedData/SourcePackages/artifacts" -path '*/bin/generate_appcast' -type f | head -n 1)"
  [[ -x "$tool" ]] || fail "No generate_appcast in the Sparkle package; run tools/build.sh build first."
  "$tool" --account "$SPARKLE_ACCOUNT" \
    --download-url-prefix "https://github.com/$REPOSITORY/releases/download/$tag/" \
    --embed-release-notes --maximum-versions "$MAXIMUM_VERSIONS_IN_FEED" "$feed"
  grep -q 'sparkle:edSignature=' "$feed/appcast.xml" || fail "The feed holds no signature."
  cp "$feed/appcast.xml" "$clone/appcast.xml"
}

commit_and_push() {
  local clone="$1" message="$2" branch="$3"
  git -C "$clone" add -A
  git -C "$clone" commit --quiet -m "$message"
  git -C "$clone" push --quiet origin "$branch"
}

step "Publish"
zip="$(release_file zip)"
dmg="$(release_file dmg)"
name="$(basename "$zip" .zip)"
[[ "$name" =~ ^$APP_NAME-([0-9]+\.[0-9]+\.[0-9]+)-[0-9.]+$ ]] || fail "$name is not named $APP_NAME-<version>-<build>"
version="${BASH_REMATCH[1]}"
tag="v$version"

rm -rf "$WORK"
mkdir -p "$WORK"
"$TOOLS_DIR/release_notes.sh" "$version" >"$WORK/notes.md"
clone_feed "$WORK/pages"
update_feed "$zip" "$tag" "$WORK/notes.md" "$WORK/pages"
ok "The feed has $APP_NAME $version, signed"

if ((dry_run)); then
  ok "Trial run: nothing left this Mac. The feed: ${WORK#"$ROOT_DIR"/}/pages/appcast.xml"
  exit 0
fi

! gh release view "$tag" --repo "$REPOSITORY" >/dev/null 2>&1 || fail "$REPOSITORY already has a release $tag."
git -C "$ROOT_DIR" push --quiet origin "$tag"
gh release create "$tag" "$zip" "$dmg" --repo "$REPOSITORY" --verify-tag \
  --title "$APP_NAME $version" --notes-file "$WORK/notes.md" >/dev/null
ok "Release $tag"

commit_and_push "$WORK/pages" "$APP_NAME $version" "$FEED_BRANCH"
ok "Feed published"

# The cask comes last, so brew installs only a version that is downloadable and in the feed.
git clone --quiet --depth 1 "https://github.com/$TAP_REPOSITORY.git" "$WORK/tap"
mkdir -p "$WORK/tap/Casks"
"$TOOLS_DIR/homebrew/cask.sh" "$zip" >"$WORK/tap/Casks/pairwise.rb"
commit_and_push "$WORK/tap" "pairwise $version" HEAD
ok "Cask pairwise $version in $TAP_REPOSITORY"
