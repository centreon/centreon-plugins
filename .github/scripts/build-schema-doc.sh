#!/usr/bin/env bash
# Renders every version of the rs-collection JSON schema as a self-contained static
# site, ready to be uploaded as a GitHub Pages artifact.
#
# Usage: build-schema-doc.sh <schema directory> <output directory> [preview banner text]
#
# The schema directory holds one 'v<N>' directory per format version, each with its own
# rs-collection.schema.json. Every version found is published, so the URL a collection
# points its "$schema" at keeps working once a newer format exists, and a new format can
# be worked on without touching the one in use.
#
# When a banner text is given, it is injected at the top of every generated page
# so a preview can never be mistaken for the published reference.

set -euo pipefail

schema_dir="$1"
output_dir="$2"
banner_text="${3:-}"

# resolved from the script location so the command works from any directory
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

mapfile -t schema_files < <(find "${schema_dir}" -mindepth 2 -maxdepth 2 -type f -name 'rs-collection.schema.json' | sort -V)

if (( ${#schema_files[@]} == 0 )) ; then
  echo "no rs-collection.schema.json found under ${schema_dir}/v*/" >&2
  exit 1
fi

# one landing page card per version, built while the versions are rendered
cards=()

for schema_file in "${schema_files[@]}" ; do
  version="$(basename "$(dirname "${schema_file}")")"

  # the directory a schema sits in is the version it is published as, so it must be the
  # one the schema claims: nothing else keeps the repository layout and the published
  # URLs from drifting apart
  schema_id="$(jq -r '."$id" // ""' "${schema_file}")"
  if [[ "${schema_id}" != *"/${version}/"* ]] ; then
    echo "${schema_file}: its \$id carries no '${version}' segment: '${schema_id}'" >&2
    exit 1
  fi

  version_dir="${output_dir}/rs-collections/snmp/${version}"
  mkdir -p "${version_dir}"

  # a published version never changes, so an editor may cache this file forever
  cp "${schema_file}" "${version_dir}/rs-collection.schema.json"

  # js_offline embeds jquery, bootstrap and the fonts next to the page, so the
  # site stays self-contained and fetches nothing from a CDN
  generate-schema-doc \
    --config template_name=js_offline \
    --config expand_buttons=true \
    "${schema_file}" \
    "${version_dir}/index.html"

  # a 0 major means beta, by the very definition of semantic versioning, so the status
  # of a version is read from its number rather than declared by hand somewhere
  if [[ "${version}" == "v0" ]] ; then
    status="Beta format: no stability guarantee, it may still change."
  else
    status="Stable format."
  fi

  cards+=("      <li>")
  cards+=("        <a class=\"card\" href=\"rs-collections/snmp/${version}/\">")
  cards+=("          <strong>$(jq -r '.title // "Collection"' "${schema_file}") &mdash; format ${version}</strong>")
  cards+=("          <span>${status}</span>")
  cards+=("        </a>")
  cards+=("      </li>")
done

# the landing page is a template listing whatever was rendered above, so a new version
# appears on it by being added to the schema directory, and nowhere else
while IFS= read -r line ; do
  if [[ "${line}" == *"<!-- SCHEMA_VERSIONS -->"* ]] ; then
    printf '%s\n' "${cards[@]}"
  else
    printf '%s\n' "${line}"
  fi
done < "${repo_root}/.github/pages/index.html" > "${output_dir}/index.html"

if [ -n "$banner_text" ]; then
  while IFS= read -r page ; do
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
  done < <(find "$output_dir" -type f -name 'index.html' | sort)
fi

find "$output_dir" -type f | sort
