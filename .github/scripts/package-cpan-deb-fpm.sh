#!/bin/bash
# Package a CPAN library as a DEB using fpm -s cpan.
#
# Required environment variables:
#   PKG_NAME             CPAN module name (e.g. Net::Curl)
#   PKG_EXT              Package extension (deb)
#   DISTRIB              Distribution (e.g. bookworm)
#   REVISION             Package revision (e.g. 1)
#   DISTRIB_SEPARATOR    Separator between revision and distrib suffix (+ or -)
#   DISTRIB_SUFFIX       Distribution suffix in package name (e.g. deb12u1)
#   VERSION              Version to build (empty = let fpm/MetaCPAN decide)
#   DEB_DEPENDENCIES     Space-separated list of --depends values
#   DEB_PROVIDES         Space-separated list of --provides values
#   NO_AUTO_DEPENDS      "true" to add --no-auto-depends
#   PREINSTALL_CPANLIBS  Space-separated CPAN libs to install before packaging
set -e

echo "default.local" | tee /etc/mailname

for CPANLIB in $PREINSTALL_CPANLIBS; do
  cpanm "$CPANLIB"
done

[ -n "$VERSION" ] && VERSION_FLAG="-v $VERSION" || VERSION_FLAG=""

PACKAGE_DEPENDENCIES=""
for DEP in $DEB_DEPENDENCIES; do
  PACKAGE_DEPENDENCIES="$PACKAGE_DEPENDENCIES --depends $DEP"
done
[ "$NO_AUTO_DEPENDS" = "true" ] && PACKAGE_DEPENDENCIES="$PACKAGE_DEPENDENCIES --no-auto-depends"

PACKAGE_PROVIDES=""
for PRV in $DEB_PROVIDES; do
  PACKAGE_PROVIDES="$PACKAGE_PROVIDES --provides $PRV"
done

ITERATION="${REVISION}${DISTRIB_SEPARATOR}${DISTRIB_SUFFIX}"

temp_file=$(mktemp)
# shellcheck disable=SC2086
if [ "$PKG_NAME" = "Libssh::Session" ]; then
  created_package=$(fpm -s cpan -t "$PKG_EXT" \
    --deb-dist "$DISTRIB" --iteration "$ITERATION" \
    --verbose --cpan-verbose --no-cpan-test \
    $PACKAGE_DEPENDENCIES $PACKAGE_PROVIDES $VERSION_FLAG \
    --name ssh-session "$PKG_NAME" \
    | tee "$temp_file" \
    | grep "Created package" \
    | grep -oP '(?<=:path=>").*?(?=")') || true
else
  created_package=$(fpm -s cpan -t "$PKG_EXT" \
    --deb-dist "$DISTRIB" --iteration "$ITERATION" \
    --verbose --cpan-verbose --no-cpan-test \
    $PACKAGE_DEPENDENCIES $PACKAGE_PROVIDES $VERSION_FLAG "$PKG_NAME" \
    | tee "$temp_file" \
    | grep "Created package" \
    | grep -oP '(?<=:path=>").*?(?=")') || true
fi

if [ -z "$created_package" ]; then
  echo "Error: fpm command failed"
  cat "$temp_file"
  exit 1
fi

dpkg-deb --verbose --contents "$created_package" || { echo "Error: dpkg-deb failed for $created_package"; exit 1; }
