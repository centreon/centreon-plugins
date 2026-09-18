#!/usr/bin/env bash
# Validates Rust SNMP collections against the format version each one declares.
#
# Usage: validate-rs-collections.sh [collection file...]
#
# Without arguments, every collection under rust-plugins/rs-collections is checked.
# Run from the root of the repository. Exits non-zero as soon as one collection is
# rejected, after having reported them all.
#
# A collection is never validated against the newest schema, only against the one its
# "format_version" names, so an older format keeps being enforced as it was written.
#
# Under GitHub Actions the problems are reported as annotations, and a missing
# check-jsonschema is an error rather than a skipped check.

set -euo pipefail

collections_dir="rust-plugins/rs-collections"
schema_dir="rust-plugins/schema"

# exit code, raised by problem()
status=0

on_github_actions() {
  [[ "${GITHUB_ACTIONS:-}" == "true" ]]
}

problem() {
  local file="$1"
  local message="$2"

  if on_github_actions ; then
    echo "::error file=${file}::${message}"
  else
    echo "${file}: ${message}" >&2
  fi
  status=1
}

check_collection() {
  local file="$1"
  local format_version schema expected_ref declared_ref

  format_version="$(jq -r '.format_version // ""' "${file}" 2>/dev/null)"
  if [[ -z "${format_version}" ]] ; then
    problem "${file}" 'declares no "format_version", the plugin will refuse it'
    return
  fi

  schema="${schema_dir}/v${format_version}/rs-collection.schema.json"
  if [[ ! -f "${schema}" ]] ; then
    problem "${file}" "declares the format version ${format_version}, but ${schema} does not exist"
    return
  fi

  # the "$schema" key is what an editor follows, so it has to be the published URL of
  # the very version the plugin will enforce. Taken from that schema's own $id rather
  # than spelled out here, so there is one place where the URL is written down.
  expected_ref="$(jq -r '."$id" // ""' "${schema}" 2>/dev/null)"
  if [[ -z "${expected_ref}" ]] ; then
    problem "${schema}" 'declares no "$id", collections cannot reference it'
    return
  fi

  declared_ref="$(jq -r '."$schema" // ""' "${file}" 2>/dev/null)"
  if [[ "${declared_ref}" != "${expected_ref}" ]] ; then
    problem "${file}" "declares \"\$schema\": \"${declared_ref}\", expected \"${expected_ref}\""
  fi

  if [[ -z "${check_jsonschema}" ]] ; then
    return
  fi

  if ! output="$("${check_jsonschema}" --schemafile "${schema}" "${file}" 2>&1)" ; then
    problem "${file}" "does not comply with ${schema}"
    echo "${output}" >&2
  fi
}

type -p jq > /dev/null || { echo "could not locate jq" >&2 ; exit 1 ; }

check_jsonschema="$(type -p check-jsonschema || true)"
if [[ -z "${check_jsonschema}" ]] ; then
  if on_github_actions ; then
    echo "::error::could not locate check-jsonschema, install it before validating collections"
    exit 1
  fi
  echo "could not locate check-jsonschema, only the declared versions are checked" >&2
fi

if (( $# > 0 )) ; then
  collections=("$@")
else
  mapfile -t collections < <(find "${collections_dir}" -type f -name '*.json' | sort)
  if (( ${#collections[@]} == 0 )) ; then
    echo "no collection found under ${collections_dir}" >&2
    exit 1
  fi
  echo "Validating ${#collections[@]} collection(s) against the format version each declares"
fi

for collection in "${collections[@]}" ; do
  check_collection "${collection}"
done

exit "${status}"
