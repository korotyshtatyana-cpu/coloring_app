#!/bin/bash
set -e

cd "$(dirname "$0")"

flutter pub get
dart run easy_localization:generate \
  -f keys \
  -O lib/src/localization/generated \
  -o locale_keys.g.dart \
  --source-dir resources/lang

echo "Core prebuild completed!"
