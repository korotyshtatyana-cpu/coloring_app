#!/bin/bash
flutter pub run build_runner build \
  --delete-conflicting-outputs

echo "Navigation router generated successfully!"