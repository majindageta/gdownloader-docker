#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

bash "$repo_dir/tests/test-build-script.sh"
bash "$repo_dir/tests/test-bootstrap.sh"
bash "$repo_dir/tests/test-dockerfile.sh"
bash "$repo_dir/tests/test-docs.sh"
bash "$repo_dir/tests/test-image.sh"
bash "$repo_dir/tests/smoke.sh"
