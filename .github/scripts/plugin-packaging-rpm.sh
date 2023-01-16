#!/bin/bash

set -e

VERSION="$1"
RELEASE="$2"
PLUGINS="$3"

for PLUGIN_NAME in $PLUGINS; do
    echo "::group::Packaging $PLUGIN_NAME"

    PACKAGE_PATH=$PLUGIN_NAME

    if [[ "$PLUGIN_NAME" =~ (.+)"=>"(.+) ]]; then
        PACKAGE_PATH=$(echo ${BASH_REMATCH[1]})
        PLUGIN_NAME=$(echo ${BASH_REMATCH[2]})
    fi

    # Process specfile
    rm -f plugin.specfile
    python3 .github/scripts/create-spec-file.py "$PACKAGE_PATH" "$PLUGIN_NAME" "$VERSION" "$RELEASE"

    rm -rf $HOME/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
    mkdir -p $HOME/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

    mv build/$PLUGIN_NAME $PLUGIN_NAME-$VERSION
    tar czf $PLUGIN_NAME-$VERSION.tar.gz $PLUGIN_NAME-$VERSION
    mv $PLUGIN_NAME-$VERSION.tar.gz $HOME/rpmbuild/SOURCES/

    cd $PLUGIN_NAME-$VERSION
    rpmbuild -ba ../plugin.specfile
    find $HOME/rpmbuild/RPMS -name *.rpm -exec mv {} /src/ \;

    cd -

    echo "::endgroup::"
done
