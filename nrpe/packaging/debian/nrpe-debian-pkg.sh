#!/bin/sh

. `dirname $0`/../common.sh

PROJECT="centreon-nrpe3"
DISTRIB="bullseye"
export VERSION="4.0.3"

# Check arguments.
if [ -z "$VERSION" -o -z "$RELEASE" ] ; then
  echo "You need to specify VERSION / RELEASE variables"
  exit 1
fi

rm -rf output
mkdir -p output
sudo rm -rf $PROJECT-$VERSION.tar.gz $PROJECT-$VERSION

# Fetch sources
curl -Lo - "https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-${VERSION}/nrpe-${VERSION}.tar.gz" | tar zxpvf -
mv nrpe-$VERSION $PROJECT-$VERSION
tar czpvf $PROJECT-$VERSION.tar.gz $PROJECT-$VERSION

# Copy debian configuration to source
cp -rv centreon-build/jobs/nrpe/debian $PROJECT-$VERSION
ls -lha $PROJECT-$VERSION

# Create and populate container.
IMAGE="registry.centreon.com/mon-build-dependencies-22.04:debian11"
cp -rv centreon-build/jobs/nrpe/nrpe-debian-pkg.container.sh .
chmod -v +x nrpe-debian-pkg.container.sh
docker run -i -v "$PWD:/usr/local/src" --entrypoint "/usr/local/src/nrpe-debian-pkg.container.sh" -e "PROJECT=$PROJECT" -e "VERSION=$VERSION" -e "COMMIT=$COMMIT" -e "AUTHOR=$AUTHOR" -e "AUTHOR_EMAIL=$AUTHOR_EMAIL" -e "DISTRIB=$DISTRIB" $IMAGE
