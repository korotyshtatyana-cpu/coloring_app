#!/bin/bash
set -e

cd "$(dirname "$0")"

flutter pub get

echo "Domain prebuild completed!"
