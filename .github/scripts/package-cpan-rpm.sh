#!/bin/bash
# Package a CPAN library as an RPM using fpm -s cpan.
#
# Required environment variables:
#   PKG_NAME             CPAN module name (e.g. JSON::Path)
#   PKG_EXT              Package extension (rpm)
#   DISTRIB              Distribution (e.g. el9)
#   REVISION             Package revision (e.g. 2)
#   VERSION              Version to build (empty = let fpm/MetaCPAN decide)
#   RPM_DEPENDENCIES     Space-separated list of --depends values
#   RPM_PROVIDES         Space-separated list of --provides values
#   NO_AUTO_DEPENDS      "true" to add --no-auto-depends
#   PREINSTALL_CPANLIBS  Space-separated CPAN libs to install before packaging
set -e

export SYBASE="/usr"
echo "default.local" | tee /etc/mailname

for CPANLIB in $PREINSTALL_CPANLIBS; do
  cpanm "$CPANLIB"
done

[ -n "$VERSION" ] && PACKAGE_VERSION="-v $VERSION" || PACKAGE_VERSION=""

PACKAGE_DEPENDENCIES=""
for DEP in $RPM_DEPENDENCIES; do
  PACKAGE_DEPENDENCIES="$PACKAGE_DEPENDENCIES --depends $DEP"
done
[ "$NO_AUTO_DEPENDS" = "true" ] && PACKAGE_DEPENDENCIES="$PACKAGE_DEPENDENCIES --no-auto-depends"

PACKAGE_PROVIDES=""
for PRV in $RPM_PROVIDES; do
  PACKAGE_PROVIDES="$PACKAGE_PROVIDES --provides $PRV"
done

temp_file=$(mktemp)
# shellcheck disable=SC2086
created_package=$(fpm -s cpan -t "$PKG_EXT" \
  --rpm-dist "$DISTRIB" --rpm-digest sha256 \
  --verbose --cpan-verbose --no-cpan-test \
  $PACKAGE_DEPENDENCIES $PACKAGE_PROVIDES $PACKAGE_VERSION \
  --iteration "$REVISION" "$PKG_NAME" \
  | tee "$temp_file" \
  | grep "Created package" \
  | grep -oP '(?<=:path=>").*?(?=")') || true

if [ -z "$created_package" ]; then
  echo "Error: fpm command failed"
  cat "$temp_file"
  exit 1
fi

rpm2cpio "$created_package" | cpio -t
