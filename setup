#!/bin/sh
#
# Radically simple personal bootstrapping tool for macOS.
# https://github.com/zero-sh/zero.sh
set -o errexit -o nounset

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v brew >/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

export PATH="/usr/local/bin:$PATH"
if ! command -v zero >/dev/null; then
    echo "Installing Zero..."
    brew install zero-sh/tap/zero
fi

zero setup "$@" --directory "$SCRIPT_DIR/.."
