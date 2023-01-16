#!/bin/bash

set -e

VERSION="$1"
RELEASE="$2"
PLUGINS="$3"

cd /src

mkdir -p centreon-plugins/plugins
cp -R .github/packaging/debian centreon-plugins/debian
mv centreon-plugins/debian/control.head.template centreon-plugins/debian/control

for PLUGIN in $PLUGINS; do

    PACKAGE_PATH=$PLUGIN

    if [[ "$PLUGIN" =~ (.+)"=>"(.+) ]]; then
        PACKAGE_PATH=$(echo ${BASH_REMATCH[1]})
        PLUGIN=$(echo ${BASH_REMATCH[2]})
    fi

	PLUGIN_NAME_LOWER=$(echo "$PLUGIN" | tr '[:upper:]' '[:lower:]')

	echo "::group::Preparing $PLUGIN_NAME_LOWER"

	mkdir centreon-plugins/plugins/$PLUGIN
	cp -R build/$PLUGIN/*.pl centreon-plugins/plugins/$PLUGIN

	# Process package files
	pkg_values=($(cat "packaging/$PACKAGE_PATH/pkg.json" | jq -r '.pkg_name,.plugin_name'))
	pkg_summary=$(echo "${pkg_values[0]}")
	plugin_name=$(echo "${pkg_values[1]}")
	deb_dependencies=$(cat "packaging/$PACKAGE_PATH/deb.json" | jq -r '.dependencies | join(",\\n  ")')

	sed -e "s/@NAME@/$PLUGIN_NAME_LOWER/g" -e "s/@SUMMARY@/$pkg_summary/g" -e "s/@REQUIRES@/$deb_dependencies/g" < centreon-plugins/debian/control.body.template >> centreon-plugins/debian/control

    cat centreon-plugins/debian/control
    # .install file
	sed -e "s/@DIR@/$PLUGIN/g" -e "s/@NAME@/$plugin_name/g" < centreon-plugins/debian/plugin.install.template >> centreon-plugins/debian/$PLUGIN_NAME_LOWER.install

	echo "::endgroup::"
done

rm -f centreon-plugins/debian/*.template
tar czf centreon-plugins-${VERSION}-${RELEASE}.tar.gz centreon-plugins
cd centreon-plugins
debmake -f "Centreon" -e "contact@centreon.com" -u "${VERSION}-${RELEASE}" -y -r "bullseye"
debuild-pbuilder --no-lintian
