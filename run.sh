#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
mkdir -p results
# On NixOS, generic upstream binaries need an FHS runtime.
runner=()
if [[ -f /etc/NIXOS ]] && command -v steam-run >/dev/null; then
  runner=(steam-run)
fi
if (($# == 0)); then
  set -- 9.0.0 9.0.0rc5 10.0.0-pre.20260104.1
fi
printf 'version\texit\timported markers\n' > results/summary.tsv
for version in "$@"; do
  echo "=== $version ==="
  status=0
  env -u _JAVA_OPTIONS -u JAVA_TOOL_OPTIONS -u BAZELISK_BASE_URL -u BAZELISK_FORMAT_URL \
    USE_BAZEL_VERSION="$version" BAZELISK_SKIP_WRAPPER=1 \
    "${runner[@]}" bazelisk --batch --nosystem_rc --nohome_rc --noworkspace_rc \
    --bazelrc="$PWD/.bazelrc" version >"results/$version.log" 2>&1 || status=$?
  # Print all output and record only successfully announced marker imports.
  tee /dev/null <"results/$version.log"
  markers=$(grep 'INFO: Reading rc options' "results/$version.log" \
    | grep -oE 'markers/[^:]+\.bazelrc' | paste -sd, - || true)
  printf '%s\t%s\t%s\n' "$version" "$status" "$markers" >> results/summary.tsv
  if ((status != 0)); then echo "FAILED: $version (exit $status)" >&2; fi
done
printf '\n=== Summary ===\n'
tee /dev/null < results/summary.tsv
# Fail if any version failed, but retain all logs.
awk -F '\t' 'NR > 1 && $2 != 0 { failed=1 } END { exit failed }' results/summary.tsv
