#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "$script_dir/.." && pwd -P)"
package_config="$repo_root/terminice/.dart_tool/package_config.json"

(
  cd "$repo_root/terminice"
  dart pub get
)

dart --packages="$package_config" "$script_dir/generate.dart"
node "$script_dir/generate_component_svgs.mjs" "$@"
