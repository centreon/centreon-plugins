#!/bin/bash

plugins_json_file="$1"
package_extension="$2"
package_distrib="$3"

# centreon-plugin-operatingsystems-linux-local

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
  pkg_values=($(jq -r '.pkg_name,.plugin_name' "$PACKAGE_FILE"))
  pkg_summary=$(echo "${pkg_values[0]}")
  plugin_name=$(echo "${pkg_values[1]}")
  contents=$(jq -r '.package_files // [] | map("  - src: \"" + .src + "\"\n    dst: \"" + .dst + "\"\n    file_info:\n      mode: " + (.file_mode // "0755")) | join("\n")' "$PACKAGE_FILE")
  conflicts=$(jq -r '.conflicts // [] | join(",")' "$PACKAGE_FILE")
  replaces=$(jq -r '.replaces // [] | join(",")' "$PACKAGE_FILE")
  provides=$(jq -r '.provides // [] | join(",")' "$PACKAGE_FILE")
  deb_dependencies=$(jq -r '(.dependencies // []) + (.dependencies_'$package_distrib' // []) | join(",\n      ")' "$DEB_PACKAGE_FILE")
  rpm_dependencies=$(jq -r '(.dependencies // []) + (.dependencies_'$package_distrib' // []) | join(",\n      ")' "$RPM_PACKAGE_FILE")
  deb_conflicts=$(jq -r '.conflicts // [] | join(",")' "$DEB_PACKAGE_FILE")
  rpm_conflicts=$(jq -r '.conflicts // [] | join(",")' "$RPM_PACKAGE_FILE")
  deb_replaces=$(jq -r '.replaces // [] | join(",")' "$DEB_PACKAGE_FILE")
  rpm_replaces=$(jq -r '.replaces // [] | join(",")' "$RPM_PACKAGE_FILE")
  deb_provides=$(jq -r '.provides // [] | join(",")' "$DEB_PACKAGE_FILE")
  rpm_provides=$(jq -r '.provides // [] | join(",")' "$RPM_PACKAGE_FILE")

awk -v contents="$contents" \
  -v pkg_summary="$pkg_summary" \
  -v plugin="$PLUGIN" \
  -v conflicts="$conflicts" \
  -v replaces="$replaces" \
  -v provides="$provides" \
  -v deb_deps="$deb_dependencies" \
  -v deb_conflicts="$deb_conflicts" \
  -v deb_replaces="$deb_replaces" \
  -v deb_provides="$deb_provides" \
  -v rpm_deps="$rpm_dependencies" \
  -v rpm_conflicts="$rpm_conflicts" \
  -v rpm_replaces="$rpm_replaces" \
  -v rpm_provides="$rpm_provides" \
'{
  gsub(/@PLUGIN_NAME@/, plugin)
  gsub(/@SUMMARY@/, pkg_summary)
  gsub(/\[@CONTENTS@\]/, contents)
  gsub(/\[@CONFLICTS@\]/, conflicts)
  gsub(/\[@REPLACES@\]/, replaces)
  gsub(/\[@PROVIDES@\]/, provides)
  gsub(/\[@DEB_DEPENDENCIES@\]/, deb_deps)
  gsub(/\[@DEB_CONFLICTS@\]/, deb_conflicts)
  gsub(/\[@DEB_REPLACES@\]/, deb_replaces)
  gsub(/\[@DEB_PROVIDES@\]/, deb_provides)
  gsub(/\[@RPM_DEPENDENCIES@\]/, rpm_deps)
  gsub(/\[@RPM_CONFLICTS@\]/, rpm_conflicts)
  gsub(/\[@RPM_REPLACES@\]/, rpm_replaces)
  gsub(/\[@RPM_PROVIDES@\]/, rpm_provides)
  print
}' .github/packaging/centreon-plugin.yaml.template >> .github/packaging/$PLUGIN.yaml

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
