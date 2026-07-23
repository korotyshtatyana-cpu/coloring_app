#!/bin/bash
flutter pub run easy_localization:generate \
  -f json \
  -O lib/src/localization \
  -o locale_keys.g.dart \
  -i resources/lang

echo "Core localization generated successfully!"