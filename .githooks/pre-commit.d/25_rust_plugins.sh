#!/bin/bash

# Get list of committed files touching rust-plugins/
mapfile -t rust_files < <(git diff --cached --name-only --diff-filter=ACMR -- rust-plugins/)

if [ "${#rust_files[@]}" -eq 0 ]; then
    exit 0
fi

echo "INFO: rust-plugins/ files staged, running the quality gate"
rust-plugins/scripts/check.sh
