#!/usr/bin/env bash
#
# Rebuild RocsMiddleware-Flowstone.zip deterministically from the tracked
# Markdown notes and YAML graph files. Run on every push via
# .github/workflows/build-zip.yml
# so the published zip stays in sync with the source of truth. May also
# be run by hand for local testing: `./scripts/build-zip.sh`.
#
# Archive shape: every note lives under a `RocsMiddleware-Flowstone/`
# top-level prefix, mirroring the shape of a github codeload archive.
# The flowstone-wasm loader strips the first directory on read, so this
# zip and an upstream `.../archive/main.zip` are interchangeable.
#
# Determinism: mtimes are pinned to the ZIP-format epoch (1980-01-01),
# entries are written in sorted order, and `zip -X` strips UID/GID and
# extra fields so the archive bytes only change when content does.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

PREFIX="RocsMiddleware-Flowstone"
mkdir -p "$STAGING/$PREFIX"

mapfile -t FILES < <(
    git ls-files '*.md' '*.yaml' '*.yml' \
        ':(exclude).github/**' \
        ':(exclude)scripts/**' \
        | sort
)

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "error: no markdown or yaml files found" >&2
    exit 1
fi

for f in "${FILES[@]}"; do
    dest="$STAGING/$PREFIX/$f"
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
    # 1980-01-01 UTC — earliest timestamp the DOS date field in a zip
    # header can represent.
    touch -d @315532800 "$dest"
done

OUT="$REPO_ROOT/RocsMiddleware-Flowstone.zip"
rm -f "$OUT"

(
    cd "$STAGING"
    for f in "${FILES[@]}"; do
        printf '%s\n' "$PREFIX/$f"
    done | zip -X -@ "$OUT" > /dev/null
)

echo "Built $OUT with ${#FILES[@]} entries."
