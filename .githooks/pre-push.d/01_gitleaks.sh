#!/usr/bin/env sh
set -eu

# scan for secrets before push
gitleaks detect \
  --no-git \
  --log-opts="--no-merges --first-parent" \
  --exit-code=2 \
  --verbose \
  --no-banner
