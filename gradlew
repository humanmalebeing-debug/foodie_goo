#!/bin/sh
set -eu
APP_HOME=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
GRADLE_VERSION=8.7
CACHE_DIR="${HOME}/.gradle-foodiego"
DIST_DIR="${CACHE_DIR}/gradle-${GRADLE_VERSION}"
if [ ! -x "${DIST_DIR}/bin/gradle" ]; then
  mkdir -p "${CACHE_DIR}"
  ZIP="${CACHE_DIR}/gradle-${GRADLE_VERSION}-bin.zip"
  if [ ! -f "$ZIP" ]; then
    curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o "$ZIP"
  fi
  rm -rf "$DIST_DIR.tmp"
  mkdir -p "$DIST_DIR.tmp"
  unzip -q "$ZIP" -d "$DIST_DIR.tmp"
  mv "$DIST_DIR.tmp/gradle-${GRADLE_VERSION}" "$DIST_DIR"
  rm -rf "$DIST_DIR.tmp"
fi
exec "$DIST_DIR/bin/gradle" "$@"
