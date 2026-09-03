#!/usr/bin/env bash
# Renders the rs-collection JSON schema as a self-contained static site,
# ready to be uploaded as a GitHub Pages artifact.
#
# Usage: build-schema-doc.sh <schema file> <output directory> [preview banner text]
#
# When a banner text is given, it is injected at the top of every generated page
# so a preview can never be mistaken for the published reference.

set -euo pipefail

schema_file="$1"
output_dir="$2"
banner_text="${3:-}"

# resolved from the script location so the command works from any directory
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

reference_dir="$output_dir/rs-collections/snmp"
mkdir -p "$reference_dir"

# the landing page links to 'rs-collections/snmp/' relatively, so the same file
# works at the site root and inside the preview subdirectory
cp "$repo_root/.github/pages/index.html" "$output_dir/index.html"

# js_offline embeds jquery, bootstrap and the fonts next to the page, so the
# site stays self-contained and fetches nothing from a CDN
generate-schema-doc \
  --config template_name=js_offline \
  --config expand_buttons=true \
  "$schema_file" \
  "$reference_dir/index.html"

if [ -n "$banner_text" ]; then
  for page in "$output_dir/index.html" "$reference_dir/index.html"; do
    BANNER_TEXT="$banner_text" python3 - "$page" <<'PY'
import os, re, sys

path = sys.argv[1]
banner = (
    '<div style="background:#b8860b;color:#fff;padding:10px 16px;'
    'font:600 14px system-ui,sans-serif;text-align:center">{}</div>'
).format(os.environ["BANNER_TEXT"])

with open(path, encoding="utf-8") as fh:
    html = fh.read()

# insert right after the opening <body ...> tag, whatever attributes it carries
html, count = re.subn(r"(<body\b[^>]*>)", r"\1" + banner, html, count=1)
if count != 1:
    sys.exit("could not locate the <body> tag in {}".format(path))

with open(path, "w", encoding="utf-8") as fh:
    fh.write(html)
PY
  done
fi

find "$output_dir" -type f | sort
