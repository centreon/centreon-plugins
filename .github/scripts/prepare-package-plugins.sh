#!/bin/bash

plugins_json_file="$1"
package_extension="$2"

for PLUGIN in $(jq -r 'to_entries[] | select(.value.build == true) | .key' $plugins_json_file); do
  PACKAGE_PATH=$PLUGIN

  if [[ "$PLUGIN" =~ (.+)"=>"(.+) ]]; then
      PACKAGE_PATH=$(echo ${BASH_REMATCH[1]})
      PLUGIN=$(echo ${BASH_REMATCH[2]})
  fi

  PLUGIN_NAME_LOWER=$(echo "$PLUGIN" | tr '[:upper:]' '[:lower:]')

  echo "::group::Preparing $PLUGIN_NAME_LOWER"

  # Process package files
  pkg_values=($(cat "packaging/$PACKAGE_PATH/pkg.json" | jq -r '.pkg_name,.plugin_name'))
  pkg_summary=$(echo "${pkg_values[0]}")
  plugin_name=$(echo "${pkg_values[1]}")
  conflicts=$(cat "packaging/$PACKAGE_PATH/pkg.json" | jq -r '.conflicts // [] | join(",")')
  replaces=$(cat "packaging/$PACKAGE_PATH/pkg.json" | jq -r '.replaces // [] | join(",")')
  provides=$(cat "packaging/$PACKAGE_PATH/pkg.json" | jq -r '.provides // [] | join(",")')
  deb_dependencies=$(cat "packaging/$PACKAGE_PATH/deb.json" | jq -r '.dependencies // [] | join(",")')
  deb_conflicts=$(cat "packaging/$PACKAGE_PATH/deb.json" | jq -r '.conflicts // [] | join(",")')
  deb_replaces=$(cat "packaging/$PACKAGE_PATH/deb.json" | jq -r '.replaces // [] | join(",")')
  deb_provides=$(cat "packaging/$PACKAGE_PATH/deb.json" | jq -r '.provides // [] | join(",")')
  rpm_dependencies=$(cat "packaging/$PACKAGE_PATH/rpm.json" | jq -r '.dependencies // [] | join(",")')
  rpm_conflicts=$(cat "packaging/$PACKAGE_PATH/rpm.json" | jq -r '.conflicts // [] | join(",")')
  rpm_replaces=$(cat "packaging/$PACKAGE_PATH/rpm.json" | jq -r '.replaces // [] | join(",")')
  rpm_provides=$(cat "packaging/$PACKAGE_PATH/rpm.json" | jq -r '.provides // [] | join(",")')

  sed -e "s/@PLUGIN_NAME@/$PLUGIN/g;" \
    -e "s/@SUMMARY@/$pkg_summary/g" \
    -e "s/@CONFLICTS@/$conflicts/g" \
    -e "s/@REPLACES@/$replaces/g" \
    -e "s/@PROVIDES@/$provides/g" \
    -e "s/@DEB_DEPENDENCIES@/$deb_dependencies/g" \
    -e "s/@DEB_CONFLICTS@/$deb_conflicts/g" \
    -e "s/@DEB_REPLACES@/$deb_replaces/g" \
    -e "s/@DEB_PROVIDES@/$deb_provides/g" \
    -e "s/@RPM_DEPENDENCIES@/$rpm_dependencies/g" \
    -e "s/@RPM_CONFLICTS@/$rpm_conflicts/g" \
    -e "s/@RPM_REPLACES@/$rpm_replaces/g" \
    -e "s/@RPM_PROVIDES@/$rpm_provides/g" \
    < .github/packaging/centreon-plugin.yaml.template \
    >> .github/packaging/$PLUGIN.yaml

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