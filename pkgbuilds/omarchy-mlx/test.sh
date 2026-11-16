#!/bin/bash
# check() refuses a release whose recorded Mesa commit differs from the recipe's pin.
set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

fail() {
  echo "not ok - $1" >&2
  exit 1
}
error() { echo "$*" >&2; }

source "$package_dir/PKGBUILD"
srcdir=$scratch/src

record() { # version, commit-or-empty
  pkgver=$1
  rm -rf "$srcdir"
  mkdir -p "$srcdir/omarchy-mlx-$1/packaging"
  [[ -z ${2:-} ]] || printf '%s\n' "$2" >"$srcdir/omarchy-mlx-$1/packaging/qualified-mesa-commit"
}

record 0.7.47 "$_mesa_commit"
_check_qualified_mesa || fail "a release that records the recipe's Mesa commit passes"

record 0.7.47 439dc032d70ab9ec7e3b40afd4efd920f75c56f2
if _check_qualified_mesa 2>"$scratch/err"; then fail "a release that records another Mesa commit is refused"; fi
grep -q "$_mesa_commit" "$scratch/err" || fail "the refusal names the recipe's pin"

record 0.7.47
if _check_qualified_mesa 2>/dev/null; then fail "a release that records no Mesa commit is refused"; fi

# 0.7.46 and older were cut before the file existed.
record 0.7.46
_check_qualified_mesa || fail "0.7.46 is exempt: its tag carries no file"

echo "ok - omarchy-mlx check() compares the release's Mesa commit with the recipe's pin"
