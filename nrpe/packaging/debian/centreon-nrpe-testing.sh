#!/bin/sh

set -e
set -x

. `dirname $0`/../common.sh

# Project.
PROJECT=centreon-nrpe
export VERSION=4.0.3

# Check arguments.
if [ -z "$VERSION" -o -z "$RELEASE" ] ; then
  echo "You need to specify VERSION and RELEASE environment variables."
  exit 1
fi

# Pull build image.
BUILD_CENTOS7=registry.centreon.com/mon-build-dependencies-20.10:centos7
docker pull "$BUILD_CENTOS7"
BUILD_alma8=registry.centreon.com/mon-build-dependencies-20.10:alma8
docker pull "$BUILD_alma8"

# Create input and output directories.
rm -rf input
mkdir input
rm -rf output-centos7
mkdir output-centos7
rm -rf output-alma8
mkdir output-alma8

# Get source tarball.
curl -Lo input/nrpe-4.0.3.tar.gz 'https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.0.3/nrpe-4.0.3.tar.gz'

# Get packaging files.
cp `dirname $0`/../../packaging/nrpe/* input/

# Build RPMs.
docker-rpm-builder dir --sign-with /home/ubuntu/docker-rpm-builder/private.gpg "$BUILD_CENTOS7" input output-centos7
docker-rpm-builder dir --sign-with /home/ubuntu/docker-rpm-builder/private.gpg "$BUILD_alma8" input output-alma8

# Copy files to server.
put_rpms "standard" "20.04" "el7" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-centos7/x86_64/*.rpm
put_rpms "standard" "20.10" "el7" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-centos7/x86_64/*.rpm
put_rpms "standard" "20.10" "el8" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-alma8/x86_64/*.rpm
put_rpms "standard" "21.04" "el7" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-centos7/x86_64/*.rpm
put_rpms "standard" "21.04" "el8" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-alma8/x86_64/*.rpm
put_rpms "standard" "21.10" "el7" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-centos7/x86_64/*.rpm
put_rpms "standard" "21.10" "el8" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-alma8/x86_64/*.rpm
put_rpms "standard" "22.04" "el7" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-centos7/x86_64/*.rpm
put_rpms "standard" "22.04" "el8" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-alma8/x86_64/*.rpm
put_rpms "standard" "22.10" "el7" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-centos7/x86_64/*.rpm
put_rpms "standard" "22.10" "el8" "testing" "x86_64" "nrpe" "$PROJECT-$VERSION-$RELEASE" output-alma8/x86_64/*.rpm
