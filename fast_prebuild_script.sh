#!/bin/bash
set -e

echo "Running all prebuild scripts..."

./core/prebuild_script_core.sh
./core_ui/prebuild_script_core_ui.sh
./domain/prebuild_script_domain.sh
./data/prebuild_script_data.sh
./navigation/prebuild_script_navigation.sh
./features/splash/prebuild_script_splash.sh
./features/gallery/prebuild_script_gallery.sh
./features/canvas/prebuild_script_canvas.sh
./features/settings/prebuild_script_settings.sh

echo "All prebuild scripts completed!"