#!/bin/sh
set -e

if [ -z "$VERSION" -o -z "$RELEASE" -o -z "$DISTRIB" ] ; then
  echo "You need to specify VERSION / RELEASE / DISTRIB variables"
  exit 1
fi

echo "################################################## PACKAGING COLLECT ##################################################"

AUTHOR="Luiz Costa"
AUTHOR_EMAIL="me@luizgustavo.pro.br"

if [ -d ./tmp ] ; then
  rm -rf ./tmp
fi

mkdir -p ./tmp
cd ./tmp
apt-cache dumpavail | dpkg --merge-avail

# libssh
apt install -y libssh-dev
yes | DEB_BUILD_OPTIONS="nocheck nodocs notest" dh-make-perl make --build --revision ${RELEASE} --cpan Libssh::Session

# libhttp-proxypac-perl
yes | DEB_BUILD_OPTIONS="nocheck nodocs notest" dh-make-perl make --build --revision ${RELEASE} --cpan HTTP::ProxyPAC

# libjmx4perl-perl
yes | DEB_BUILD_OPTIONS="nocheck nodocs notest" dh-make-perl make --build --revision ${RELEASE} --cpan JMX::Jmx4Perl

# libdevice-modbus-rtu-perl
yes | DEB_BUILD_OPTIONS="nocheck nodocs notest" dh-make-perl make --build --version 0.022-${RELEASE} --cpan Device::Modbus::RTU::Client

# libdevice-modbus-tcp-perl
yes | DEB_BUILD_OPTIONS="nocheck nodocs notest" dh-make-perl make --build --version 0.026-${RELEASE} --cpan Device::Modbus::TCP::Client

# libemail-send-smtp-gmail-perl
yes | DEB_BUILD_OPTIONS="nocheck nodocs notest" dh-make-perl make --build --revision ${RELEASE} --cpan Email::Send::SMTP::Gmail    

# Process debian configuration to plugins
python3 /src/centreon-plugins/ci/scripts/gen-configuration.py

tar czpf centreon-plugins-$VERSION.tar.gz centreon-plugins
cd centreon-plugins/
cp -rf ci/debian .
debmake -f "${AUTHOR}" -e "${AUTHOR_EMAIL}" -u "$VERSION" -y -r "$RELEASE"
debuild-pbuilder
cd ../

if [ -d "$DISTRIB" ] ; then
  rm -rf "$DISTRIB"
fi
mkdir $DISTRIB
mv tmp/libssh-session-perl_0.8-${RELEASE}_amd64.deb $DISTRIB/
mv tmp/libhttp-proxypac-perl_0.31-${RELEASE}_all.deb $DISTRIB/
mv tmp/libjmx4perl-perl_1.13-${RELEASE}_all.deb $DISTRIB/
mv tmp/libdevice-modbus-rtu-perl_0.022-${RELEASE}_all.deb $DISTRIB/
mv tmp/libdevice-modbus-tcp-perl_0.026-${RELEASE}_all.deb $DISTRIB/
mv tmp/libemail-send-smtp-gmail-perl_1.35-${RELEASE}_all.deb $DISTRIB/
mv *.deb $DISTRIB/
