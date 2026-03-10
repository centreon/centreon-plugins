#!/bin/bash
# Package a CPAN library as a DEB using dh-make-perl.
#
# Required environment variables:
#   PKG_NAME             CPAN module name (e.g. JMX::Jmx4Perl)
#   DISTRIB              Distribution (e.g. bookworm)
#   REVISION             Package revision (e.g. 1)
#   DISTRIB_SEPARATOR    Separator between revision and distrib suffix (+ or -)
#   DISTRIB_SUFFIX       Distribution suffix in package name (e.g. deb12u1)
#   VERSION              Version to build (empty = latest)
#   PREINSTALL_CPANLIBS  Space-separated CPAN libs to install before packaging
set -e

echo "default.local" | tee /etc/mailname

for CPANLIB in $PREINSTALL_CPANLIBS; do
  cpanm "$CPANLIB"
done

[ -n "$VERSION" ] && VERSION_FLAG="--version $VERSION" || VERSION_FLAG=""

ITERATION="${REVISION}${DISTRIB_SEPARATOR}${DISTRIB_SUFFIX}"

# Run from a build subdirectory so dh-make-perl places the .deb at ../
# which resolves to the mounted workspace root /work (accessible on the runner).
mkdir -p /work/build
cd /work/build

# shellcheck disable=SC2086
created_package=$(DEB_BUILD_OPTIONS="nocheck nodocs notest" dh-make-perl make \
  --dist "$DISTRIB" --build $VERSION_FLAG \
  --revision "$ITERATION" \
  --cpan "$PKG_NAME" \
  | grep "building package" \
  | grep -oP "(?<=in '../).*.deb(?=')") || true

if [ -z "$created_package" ]; then
  echo "Error: dh-make-perl command failed"
  exit 1
fi

dpkg-deb --contents "../$created_package" || { echo "Error: dpkg-deb failed for $created_package"; exit 1; }
