#!/usr/bin/env bash
# Copy libcurl-4.dll and its full mingw dependency closure into Strawberry's
# c/bin, and record the DLL basenames in curl-deps.txt for the pp --link step.
#
# Runs under the msys2 shell on the GitHub Windows runner. Uses only absolute
# paths, so it is independent of the current working directory.
set -euo pipefail

export PATH="/mingw64/bin:/usr/bin:/bin:${PATH}"

src="/mingw64/bin/libcurl-4.dll"
dest="/c/Strawberry/c/bin"
manifest="${dest}/curl-deps.txt"

# ldd prints only the DEPENDENCIES, not libcurl-4.dll itself, so include it
# explicitly -- Net::Curl's Curl.xs.dll imports libcurl-4.dll directly and must
# find it in the bundle. Keep only the mingw64 DLLs.
closure="$( { echo "${src}"; ldd "${src}" | grep -oE '/mingw64/bin/[^[:space:]]+\.dll'; } | sort -u )"

if [ -z "${closure}" ]; then
  echo "ERROR: could not resolve the libcurl dependency closure" >&2
  exit 1
fi

: > "${manifest}"
while IFS= read -r dll; do
  [ -n "${dll}" ] || continue
  cp -f "${dll}" "${dest}/"
  basename "${dll}" >> "${manifest}"
done <<< "${closure}"

echo "curl closure ($(wc -l < "${manifest}") dlls):"
cat "${manifest}"
