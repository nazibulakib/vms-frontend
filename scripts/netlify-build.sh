#!/usr/bin/env bash
set -euo pipefail

: "${API_BASE_URL:?Set API_BASE_URL in Netlify to the production API URL ending in /api/v1}"
API_BASE_URL="${API_BASE_URL%/}"

if [[ "$API_BASE_URL" != https://* || "$API_BASE_URL" != */api/v1 ]]; then
  echo "API_BASE_URL must be an HTTPS URL ending in /api/v1." >&2
  exit 1
fi

if [[ -n "${FLUTTER_SDK_PATH:-}" ]]; then
  FLUTTER_ROOT="$FLUTTER_SDK_PATH"
else
  FLUTTER_REVISION="$(sed -n 's/^  revision: "\([^"]*\)"/\1/p' .metadata)"
  if [[ -z "$FLUTTER_REVISION" ]]; then
    echo "Could not read the Flutter SDK revision from .metadata." >&2
    exit 1
  fi

  CACHE_ROOT="${NETLIFY_CACHE_DIR:-${TMPDIR:-/tmp}/netlify-cache}"
  FLUTTER_ROOT="$CACHE_ROOT/flutter-sdk-$FLUTTER_REVISION"
  if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
    mkdir -p "$CACHE_ROOT"
    git clone --depth 1 --branch stable --no-checkout \
      https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
  fi

  if ! git -C "$FLUTTER_ROOT" cat-file -e "$FLUTTER_REVISION^{commit}" 2>/dev/null; then
    git -C "$FLUTTER_ROOT" fetch --depth 1 origin "$FLUTTER_REVISION"
  fi
  git -C "$FLUTTER_ROOT" checkout --detach "$FLUTTER_REVISION"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"
flutter config --enable-web
flutter pub get
flutter build web --release --dart-define="API_BASE_URL=$API_BASE_URL"
