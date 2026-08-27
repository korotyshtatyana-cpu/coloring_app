#!/bin/bash
set -e

cd "$(dirname "$0")"

flutter pub get

echo "Core UI prebuild completed!"
