#!/bin/bash
echo "Running all prebuild scripts..."

./core/prebuild_script_core.sh
./core_ui/prebuild_script_core_ui.sh
./domain/prebuild_script_domain.sh
./data/prebuild_script_data.sh
./navigation/prebuild_script_navigation.sh

echo "All prebuild scripts completed!"