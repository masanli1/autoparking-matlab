#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) not found: https://cli.github.com/" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "Not logged in. Run: gh auth login" >&2
  exit 1
fi

if [ ! -d .git ]; then
  git init
  git add .
  git commit -m "feat: AutoParking MATLAB v1.0.0"
fi

gh repo create autoparking-matlab --public --source=. --remote=origin --push
echo "done. GitHub user: masanli1. If your account differs, update README.md / CITATION.cff first."
