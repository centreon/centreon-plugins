#!/bin/sh
set -ex

if [ -z "$VERSION" -o -z "$RELEASE" -o -z "$DISTRIB" ] ; then
  echo "You need to specify VERSION / RELEASE / DISTRIB variables"
  exit 1
fi

echo "################################################## PACKAGING COLLECT ##################################################"

AUTHOR="Luiz Costa"
AUTHOR_EMAIL="me@luizgustavo.pro.br"

if [ -d /build ]; then
  rm -rf /build
fi
mkdir -p /build
cd /build

# fix version to debian format accept
VERSION="$(echo $VERSION | sed 's/-/./g')"

# Make perl-VMware-vSphere dependecy
wget -O - https://gitlab.labexposed.com/centreon-lab/perl-VMware-vSphere/-/raw/master/storage/VMware-vSphere-Perl-SDK-7.0.0-17698549.x86_64.tar.gz | tar zxvf -
mv vmware-vsphere-cli-distrib vmware-vsphere-cli
tar czvf vmware-vsphere-cli-7.0.0.tar.gz vmware-vsphere-cli
cd vmware-vsphere-cli
git clone https://github.com/centreon-lab/perl-vmware-debian debian
debmake -f "${AUTHOR}" -e "${AUTHOR_EMAIL}" -u "7.0.0" -y -r "${DISTRIB}"
debuild-pbuilder
cd ..

cp -rv /src/centreon-vmware /build/
mv -v /build/centreon-vmware /build/centreon-plugin-virtualization-vmware-daemon
(cd /build && tar czvpf - centreon-plugin-virtualization-vmware-daemon) | dd of=centreon-plugin-virtualization-vmware-daemon-$VERSION.tar.gz
cp -rv /src/centreon-vmware/ci/debian /build/centreon-plugin-virtualization-vmware-daemon/

cd /build/centreon-plugin-virtualization-vmware-daemon
debmake -f "${AUTHOR}" -e "${AUTHOR_EMAIL}" -u "$VERSION" -y -r "$DISTRIB"
debuild-pbuilder
cd /build

if [ -d "$DISTRIB" ] ; then
  rm -rf "$DISTRIB"
fi
mkdir $DISTRIB
mv /build/*.deb $DISTRIB/
ls -lart /build/$DISTRIB
mv /build/$DISTRIB/*.deb /src
