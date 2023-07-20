#!/bin/sh -x

cd /usr/local/src/$PROJECT-$VERSION
sed -i "s/^centreon:version=.*$/centreon:version=$(echo $VERSION | egrep -o '^[0-9][0-9].[0-9][0-9]')/" debian/substvars
debmake -f "${AUTHOR}" -e "${AUTHOR_EMAIL}" -y -r ${DISTRIB}
debuild-pbuilder
