#!/bin/bash

plugins_json_file="$1"
package_extension="$2"
package_distrib="$3"

for PLUGIN in $(jq -r 'to_entries[] | select(.value.build == true) | .key' $plugins_json_file); do
  PACKAGE_PATH=$PLUGIN

  if [[ "$PLUGIN" =~ (.+)"=>"(.+) ]]; then
      PACKAGE_PATH=$(echo ${BASH_REMATCH[1]})
      PLUGIN=$(echo ${BASH_REMATCH[2]})
  fi

  PACKAGE_FILE="packaging/$PACKAGE_PATH/pkg.json"
  DEB_PACKAGE_FILE="packaging/$PACKAGE_PATH/deb.json"
  RPM_PACKAGE_FILE="packaging/$PACKAGE_PATH/rpm.json"

  PLUGIN_NAME_LOWER=$(echo "$PLUGIN" | tr '[:upper:]' '[:lower:]')

  echo "::group::Preparing $PLUGIN_NAME_LOWER"

  # Process package files
  pkg_summary=$(jq -r '.pkg_summary' "$PACKAGE_FILE")
  # More than half the packages still carry the placeholder summary "Centreon Plugin", which says
  # less than their own name. Keep the previous behaviour for those until they get a real summary.
  if [[ "${pkg_summary}" == "Centreon Plugin" ]]; then
    pkg_summary=$(jq -r '.pkg_name' "$PACKAGE_FILE")
  fi
  contents=$(jq -r '.package_files // [] | map("  - src: \"" + .src + "\"\n    dst: \"" + .dst + "\"\n    file_info:\n      mode: " + (.file_mode // "0755")) | join("\n")' "$PACKAGE_FILE")
  conflicts=$(jq -r '.conflicts // [] | join(",")' "$PACKAGE_FILE")
  replaces=$(jq -r '.replaces // [] | join(",")' "$PACKAGE_FILE")
  provides=$(jq -r '.provides // [] | join(",")' "$PACKAGE_FILE")
  deb_dependencies=$(jq -r '(.dependencies // []) + (.dependencies_'$package_distrib' // []) | join(",")' "$DEB_PACKAGE_FILE")
  rpm_dependencies=$(jq -r '(.dependencies // []) + (.dependencies_'$package_distrib' // []) | join(",")' "$RPM_PACKAGE_FILE")
  deb_conflicts=$(jq -r '.conflicts // [] | join(",")' "$DEB_PACKAGE_FILE")
  rpm_conflicts=$(jq -r '.conflicts // [] | join(",")' "$RPM_PACKAGE_FILE")
  deb_replaces=$(jq -r '.replaces // [] | join(",")' "$DEB_PACKAGE_FILE")
  rpm_replaces=$(jq -r '.replaces // [] | join(",")' "$RPM_PACKAGE_FILE")
  deb_provides=$(jq -r '.provides // [] | join(",")' "$DEB_PACKAGE_FILE")
  rpm_provides=$(jq -r '.provides // [] | join(",")' "$RPM_PACKAGE_FILE")
  skip_default_dependencies=$(jq -r '.skip_default_dependencies // false' "$PACKAGE_FILE")

  # Packages shipping only package_files (the rust collections) embed no perl plugin: without this
  # guard the template would package the framework-only centreon_plugins.pl that fatpack-plugins.pl
  # produces for an empty "files". The plugin name is resolved here rather than through
  # @PLUGIN_NAME@, whose gsub runs before the one substituting this block.
  fatpack_contents=""
  if (( $(jq -r '(.files // []) | length' "$PACKAGE_FILE") > 0 )); then
    fatpack_contents=$(printf '  - src: "../../build/%s/*"\n    dst: "/usr/lib/centreon/plugins/"\n    file_info:\n      mode: 0775' "$PLUGIN")
  fi

  # values go through the environment and are replaced literally: awk -v eats backslashes and
  # gsub turns "&" into the matched token
  TPL_PLUGIN_NAME="$PLUGIN" \
  TPL_SUMMARY="$pkg_summary" \
  TPL_FATPACK_CONTENTS="$fatpack_contents" \
  TPL_CONTENTS="$contents" \
  TPL_CONFLICTS="$conflicts" \
  TPL_REPLACES="$replaces" \
  TPL_PROVIDES="$provides" \
  TPL_DEB_DEPENDENCIES="$deb_dependencies" \
  TPL_DEB_CONFLICTS="$deb_conflicts" \
  TPL_DEB_REPLACES="$deb_replaces" \
  TPL_DEB_PROVIDES="$deb_provides" \
  TPL_RPM_DEPENDENCIES="$rpm_dependencies" \
  TPL_RPM_CONFLICTS="$rpm_conflicts" \
  TPL_RPM_REPLACES="$rpm_replaces" \
  TPL_RPM_PROVIDES="$rpm_provides" \
  awk '
function replace(line, token, value,    out, i) {
  out = ""
  while ((i = index(line, token)) > 0) {
    out = out substr(line, 1, i - 1) value
    line = substr(line, i + length(token))
  }
  return out line
}
BEGIN {
  n = split("PLUGIN_NAME SUMMARY FATPACK_CONTENTS CONTENTS CONFLICTS REPLACES PROVIDES DEB_DEPENDENCIES DEB_CONFLICTS DEB_REPLACES DEB_PROVIDES RPM_DEPENDENCIES RPM_CONFLICTS RPM_REPLACES RPM_PROVIDES", tokens, " ")
}
{
  line = $0
  for (t = 1; t <= n; t++) {
    line = replace(line, "@" tokens[t] "@", ENVIRON["TPL_" tokens[t]])
  }
  print line
}' .github/packaging/centreon-plugin.yaml.template > .github/packaging/$PLUGIN.yaml

  if [ "$skip_default_dependencies" = "true" ]; then
    # Remove default dependencies
    # First dependencies block is for rpm, second for deb
    awk -v rpm_deps="$rpm_dependencies" \
        -v deb_deps="$deb_dependencies" '
/^[[:space:]]*depends:[[:space:]]*\[/ {
  match($0,/^[[:space:]]*/)
  nb_space=substr($0,1,RLENGTH)
  count++
  if (count == 1) { print nb_space "depends: [" rpm_deps "]"; skip=1; next }
  if (count == 2) { print nb_space "depends: [" deb_deps "]"; skip=1; next }
}
skip && /^[[:space:]]*]/ {
  skip=0
  next
}
!skip
' .github/packaging/$PLUGIN.yaml > .github/packaging/$PLUGIN.yaml.tmp && mv .github/packaging/$PLUGIN.yaml.tmp .github/packaging/$PLUGIN.yaml
  fi

  if [ "$package_extension" = "rpm" ]; then
    sed -i "s/@PACKAGE_NAME@/$PLUGIN/g" \
      .github/packaging/$PLUGIN.yaml
  else
    sed -i "s/@PACKAGE_NAME@/$PLUGIN_NAME_LOWER/g" \
      .github/packaging/$PLUGIN.yaml
  fi

  cat .github/packaging/$PLUGIN.yaml

  echo "::endgroup::"
done
