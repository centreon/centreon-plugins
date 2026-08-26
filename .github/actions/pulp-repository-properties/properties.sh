#!/usr/bin/env bash
set -euo pipefail

if [[ -z "$MODULE_NAME" || -z "$DISTRIB" || -z "$STABILITY" || -z "$IS_CLOUD" ]]; then
  echo "::error::some mandatory inputs are empty, please check the logs."
  exit 1
fi

# repository_name selects the standard (open-source), business (paid) or plugins
# repository family. standard/business have "-internal" variants: either a cloud
# context (is_cloud) or an explicit "-internal" suffix means the internal repo.
# plugins repositories are not versioned (packages carry their own date-based
# versioning), so the version input is only required for the other families.
REPOSITORY_TYPE="${REPOSITORY_TYPE:-standard}"
case "$REPOSITORY_TYPE" in
  standard | standard-internal) REPO_BASE="standard" ;;
  business | business-internal) REPO_BASE="business" ;;
  plugins) REPO_BASE="plugins" ;;
  *)
    echo "::error::Unsupported repository_name: $REPOSITORY_TYPE"
    exit 1
    ;;
esac

if [[ "$REPO_BASE" != "plugins" && -z "$VERSION" ]]; then
  echo "::error::version input is mandatory for the $REPOSITORY_TYPE repository family."
  exit 1
fi

# parse-distrib emits the el family either generically ("el") or per version
# ("el7"/"el8"/"el9"/"el10" on centreon-collect); normalize it to "el" so the
# family checks below are portable across both conventions.
DEB_PREFIX=""
case "$DISTRIB_FAMILY" in
  el | el[0-9]*)
    DISTRIB_FAMILY="el"
    ;;
  debian) DEB_PREFIX="apt-" ;;
  ubuntu) DEB_PREFIX="ubuntu-" ;;
  *)
    echo "::error::Unsupported distribution family: $DISTRIB_FAMILY"
    exit 1
    ;;
esac

# uniform stability segments across every edition (plugins included):
# unstable, testing-release, testing-hotfix, stable
TESTING_SEGMENT="testing"
TESTING_POOL_SEGMENT="testing"
if [[ "$RELEASE_TYPE" == "release" || "$RELEASE_TYPE" == "hotfix" ]]; then
  TESTING_SEGMENT="testing-$RELEASE_TYPE"
  TESTING_POOL_SEGMENT="testing/$RELEASE_TYPE"
fi

STABILITY_SEGMENT="$STABILITY"
POOL_SEGMENT="$STABILITY"
if [[ "$STABILITY" == "testing" ]]; then
  STABILITY_SEGMENT="$TESTING_SEGMENT"
  POOL_SEGMENT="$TESTING_POOL_SEGMENT"
fi

REPOSITORY_PREFIX=""
BASE_PATH_PREFIX=""
LEGACY_BASE_PATH_PREFIX=""
LEGACY_TESTING_BASE_PATH_PREFIX=""
LEGACY_STABLE_BASE_PATH_PREFIX=""
LEGACY_BASE_PATH=""
LEGACY_TESTING_BASE_PATH=""
LEGACY_STABLE_BASE_PATH=""
TESTING_REPOSITORY_PREFIX=""
TESTING_BASE_PATH_PREFIX=""
STABLE_REPOSITORY_PREFIX=""
STABLE_BASE_PATH_PREFIX=""
REPOSITORY_NAME=""
BASE_PATH=""
SUITE=""
TESTING_REPOSITORY_NAME=""
TESTING_BASE_PATH=""
TESTING_SUITE=""
STABLE_SUITE=""
STABLE_LEGACY_SUITE=""
POOL_PATH=""
TESTING_POOL_PATH=""
STABLE_POOL_PATH=""

if [[ "$REPO_BASE" == "plugins" ]]; then
  # plugins repositories are not versioned: rpm paths carry no version segment
  # and deb suites are the plain distribution codename.
  if [[ "$DELIVERY_TYPE" == "feature" ]]; then
    echo "::notice::Feature delivery is not supported for plugins packages, skipping delivery."
    echo "skip_delivery=true" >> "$GITHUB_OUTPUT"
    exit 0
  fi

  if [[ "$DISTRIB_FAMILY" == "el" ]]; then
    REPOSITORY_PREFIX="rpm-$DISTRIB-$STABILITY_SEGMENT"
    BASE_PATH_PREFIX="rpm/$DISTRIB/$STABILITY_SEGMENT"
    TESTING_REPOSITORY_PREFIX="rpm-$DISTRIB-$TESTING_SEGMENT"
    TESTING_BASE_PATH_PREFIX="rpm/$DISTRIB/$TESTING_SEGMENT"
    STABLE_REPOSITORY_PREFIX="rpm-$DISTRIB-stable"
    STABLE_BASE_PATH_PREFIX="rpm/$DISTRIB/stable"
    LEGACY_SEGMENT_RPM="$STABILITY_SEGMENT"
    [[ "$STABILITY_SEGMENT" == "testing-release" ]] && LEGACY_SEGMENT_RPM="testing"
    LEGACY_TESTING_SEGMENT_RPM="$TESTING_SEGMENT"
    [[ "$TESTING_SEGMENT" == "testing-release" ]] && LEGACY_TESTING_SEGMENT_RPM="testing"
    LEGACY_BASE_PATH_PREFIX="rpm-$REPO_BASE/$DISTRIB/$LEGACY_SEGMENT_RPM"
    LEGACY_TESTING_BASE_PATH_PREFIX="rpm-$REPO_BASE/$DISTRIB/$LEGACY_TESTING_SEGMENT_RPM"
    LEGACY_STABLE_BASE_PATH_PREFIX="rpm-$REPO_BASE/$DISTRIB/stable"
  else
    # one deb repository per stability (base path = repository name), suites
    # carry the plain codename only
    REPOSITORY_NAME="${DEB_PREFIX}${STABILITY_SEGMENT}"
    BASE_PATH="$REPOSITORY_NAME"
    # historical layout: one repository per stability with plain-codename
    # suites; the legacy stability (bare "testing") lives in the front prefix
    LEGACY_SEGMENT="$STABILITY_SEGMENT"
    [[ "$STABILITY_SEGMENT" == "testing-release" ]] && LEGACY_SEGMENT="testing"
    LEGACY_TESTING_SEGMENT="$TESTING_SEGMENT"
    [[ "$TESTING_SEGMENT" == "testing-release" ]] && LEGACY_TESTING_SEGMENT="testing"
    SUITE="$DISTRIB"
    TESTING_REPOSITORY_NAME="${DEB_PREFIX}${TESTING_SEGMENT}"
    TESTING_BASE_PATH="$TESTING_REPOSITORY_NAME"
    TESTING_SUITE="$DISTRIB"
    STABLE_REPOSITORY_NAME="${DEB_PREFIX}stable"
    STABLE_BASE_PATH="$STABLE_REPOSITORY_NAME"
    STABLE_SUITE="$DISTRIB"
    # legacy (front) paths used by the content verifications: the CI exercises
    # the compatibility rewrites on every delivery
    LEGACY_BASE_PATH="${DEB_PREFIX}${REPO_BASE}-${LEGACY_SEGMENT}"
    LEGACY_TESTING_BASE_PATH="${DEB_PREFIX}${REPO_BASE}-${LEGACY_TESTING_SEGMENT}"
    LEGACY_STABLE_BASE_PATH="${DEB_PREFIX}${REPO_BASE}-stable"
    POOL_PATH="pool/$POOL_SEGMENT/$MODULE_NAME"
    TESTING_POOL_PATH="pool/$TESTING_POOL_SEGMENT/$MODULE_NAME"
    STABLE_POOL_PATH="pool/stable/$MODULE_NAME"
  fi
elif [[ "$DELIVERY_TYPE" == "feature" ]]; then
  if [[ "$DISTRIB_FAMILY" != "el" ]]; then
    echo "::notice::Feature delivery is not supported for $DISTRIB_FAMILY packages, skipping delivery."
    echo "skip_delivery=true" >> "$GITHUB_OUTPUT"
    exit 0
  fi

  FEATURE_TICKET=$(echo "$GH_HEAD_REF" | grep -oE 'MON-[0-9]+' | head -1 || true)
  if [[ -z "$FEATURE_TICKET" ]]; then
    echo "::error::Cannot extract the feature ticket from branch name $GH_HEAD_REF"
    exit 1
  fi

  REPOSITORY_PREFIX="rpm-feature-$FEATURE_TICKET-$VERSION-$DISTRIB-$STABILITY"
  BASE_PATH_PREFIX="rpm-feature/$FEATURE_TICKET/$VERSION/$DISTRIB/$STABILITY"
  LEGACY_BASE_PATH_PREFIX="rpm-$REPO_BASE-feature/$FEATURE_TICKET/$VERSION/$DISTRIB/$STABILITY"
else
  RPM_ROOT="rpm"
  DEB_INFIX=""
  if [[ "$IS_CLOUD" == "true" || "$REPOSITORY_TYPE" == *-internal ]]; then
    RPM_ROOT="rpm-internal"
    DEB_INFIX="internal-"
  fi

  if [[ "$DISTRIB_FAMILY" == "el" ]]; then
    REPOSITORY_PREFIX="$RPM_ROOT-$VERSION-$DISTRIB-$STABILITY_SEGMENT"
    BASE_PATH_PREFIX="$RPM_ROOT/$VERSION/$DISTRIB/$STABILITY_SEGMENT"
    TESTING_REPOSITORY_PREFIX="$RPM_ROOT-$VERSION-$DISTRIB-$TESTING_SEGMENT"
    TESTING_BASE_PATH_PREFIX="$RPM_ROOT/$VERSION/$DISTRIB/$TESTING_SEGMENT"
    STABLE_REPOSITORY_PREFIX="$RPM_ROOT-$VERSION-$DISTRIB-stable"
    STABLE_BASE_PATH_PREFIX="$RPM_ROOT/$VERSION/$DISTRIB/stable"
    # legacy (front) paths used by the content verifications (the front also
    # accepts the historical token'd business form)
    LEGACY_RPM_ROOT="rpm-$REPO_BASE"
    [[ "$RPM_ROOT" == "rpm-internal" ]] && LEGACY_RPM_ROOT="rpm-$REPO_BASE-internal"
    LEGACY_BASE_PATH_PREFIX="$LEGACY_RPM_ROOT/$VERSION/$DISTRIB/$STABILITY_SEGMENT"
    LEGACY_TESTING_BASE_PATH_PREFIX="$LEGACY_RPM_ROOT/$VERSION/$DISTRIB/$TESTING_SEGMENT"
    LEGACY_STABLE_BASE_PATH_PREFIX="$LEGACY_RPM_ROOT/$VERSION/$DISTRIB/stable"
  else
    # one deb repository per stability (base path = repository name), shared by
    # every major version: the version lives in the suite name only
    # (e.g. "trixie-26.09")
    REPOSITORY_NAME="${DEB_PREFIX}${DEB_INFIX}${STABILITY_SEGMENT}"
    BASE_PATH="$REPOSITORY_NAME"
    # suites keep their historical stability-suffixed names so the legacy
    # client lines (deb .../apt-standard/ trixie-26.10-stable main) work
    # through the content-front rewrites; each suite lives in its own
    # per-stability repository regardless
    SUITE="$DISTRIB-$VERSION-$STABILITY_SEGMENT"
    TESTING_REPOSITORY_NAME="${DEB_PREFIX}${DEB_INFIX}${TESTING_SEGMENT}"
    TESTING_BASE_PATH="$TESTING_REPOSITORY_NAME"
    TESTING_SUITE="$DISTRIB-$VERSION-$TESTING_SEGMENT"
    STABLE_REPOSITORY_NAME="${DEB_PREFIX}${DEB_INFIX}stable"
    STABLE_BASE_PATH="$STABLE_REPOSITORY_NAME"
    STABLE_SUITE="$DISTRIB-$VERSION-stable"
    # 24.x standard clients use the dedicated legacy stable repos
    # (apt-standard-24.10-stable/) with plain-codename suites: the promote
    # mirrors its associations into that suite
    if [[ "$REPO_BASE" == "standard" && -z "$DEB_INFIX" ]] \
      && [[ "$VERSION" == "24.04" || "$VERSION" == "24.10" ]]; then
      STABLE_LEGACY_SUITE="$DISTRIB"
    fi
    LEGACY_DEB_ROOT="${DEB_PREFIX}${REPO_BASE}"
    [[ -n "$DEB_INFIX" ]] && LEGACY_DEB_ROOT="${DEB_PREFIX}${REPO_BASE}-internal"
    LEGACY_BASE_PATH="$LEGACY_DEB_ROOT"
    LEGACY_TESTING_BASE_PATH="$LEGACY_DEB_ROOT"
    LEGACY_STABLE_BASE_PATH="$LEGACY_DEB_ROOT"
    POOL_PATH="pool/$VERSION/$POOL_SEGMENT/$MODULE_NAME"
    TESTING_POOL_PATH="pool/$VERSION/$TESTING_POOL_SEGMENT/$MODULE_NAME"
    STABLE_POOL_PATH="pool/$VERSION/stable/$MODULE_NAME"
  fi
fi

# unless a dedicated stable repository was selected above, stable shares the
# delivery repository (rpm resolves stable through the *_PREFIX variables)
STABLE_REPOSITORY_NAME="${STABLE_REPOSITORY_NAME:-$REPOSITORY_NAME}"
STABLE_BASE_PATH="${STABLE_BASE_PATH:-$BASE_PATH}"

# one Pulp Domain per edition; stable and non-stable repositories share it
# ("-internal"/cloud repos too). The stable/non-stable write boundary is the
# repository name, enforced server-side by name-scoped grants. stable_domain
# is kept as a distinct output for the scripts that address the stable tier,
# even though it now always equals domain.
DOMAIN="$REPO_BASE"
STABLE_DOMAIN="$DOMAIN"

echo "[DEBUG] - repository_type: $REPOSITORY_TYPE"
echo "[DEBUG] - repository_prefix: $REPOSITORY_PREFIX"
echo "[DEBUG] - base_path_prefix: $BASE_PATH_PREFIX"
echo "[DEBUG] - testing_repository_prefix: $TESTING_REPOSITORY_PREFIX"
echo "[DEBUG] - testing_base_path_prefix: $TESTING_BASE_PATH_PREFIX"
echo "[DEBUG] - stable_repository_prefix: $STABLE_REPOSITORY_PREFIX"
echo "[DEBUG] - stable_base_path_prefix: $STABLE_BASE_PATH_PREFIX"
echo "[DEBUG] - repository_name: $REPOSITORY_NAME"
echo "[DEBUG] - base_path: $BASE_PATH"
echo "[DEBUG] - suite: $SUITE"
echo "[DEBUG] - testing_repository_name: $TESTING_REPOSITORY_NAME"
echo "[DEBUG] - testing_base_path: $TESTING_BASE_PATH"
echo "[DEBUG] - testing_suite: $TESTING_SUITE"
echo "[DEBUG] - stable_suite: $STABLE_SUITE"
echo "[DEBUG] - pool_path: $POOL_PATH"
echo "[DEBUG] - testing_pool_path: $TESTING_POOL_PATH"
echo "[DEBUG] - stable_pool_path: $STABLE_POOL_PATH"
echo "[DEBUG] - domain: $DOMAIN"
echo "[DEBUG] - stable_domain: $STABLE_DOMAIN"

{
  echo "skip_delivery=false"
  echo "repository_prefix=$REPOSITORY_PREFIX"
  echo "base_path_prefix=$BASE_PATH_PREFIX"
  echo "legacy_base_path_prefix=$LEGACY_BASE_PATH_PREFIX"
  echo "legacy_testing_base_path_prefix=$LEGACY_TESTING_BASE_PATH_PREFIX"
  echo "legacy_stable_base_path_prefix=$LEGACY_STABLE_BASE_PATH_PREFIX"
  echo "testing_repository_prefix=$TESTING_REPOSITORY_PREFIX"
  echo "testing_base_path_prefix=$TESTING_BASE_PATH_PREFIX"
  echo "stable_repository_prefix=$STABLE_REPOSITORY_PREFIX"
  echo "stable_base_path_prefix=$STABLE_BASE_PATH_PREFIX"
  echo "repository_name=$REPOSITORY_NAME"
  echo "base_path=$BASE_PATH"
  echo "legacy_base_path=$LEGACY_BASE_PATH"
  echo "legacy_testing_base_path=$LEGACY_TESTING_BASE_PATH"
  echo "legacy_stable_base_path=$LEGACY_STABLE_BASE_PATH"
  echo "suite=$SUITE"
  echo "testing_repository_name=$TESTING_REPOSITORY_NAME"
  echo "testing_base_path=$TESTING_BASE_PATH"
  echo "testing_suite=$TESTING_SUITE"
  echo "stable_suite=$STABLE_SUITE"
  echo "stable_legacy_suite=$STABLE_LEGACY_SUITE"
  echo "stable_repository_name=$STABLE_REPOSITORY_NAME"
  echo "stable_base_path=$STABLE_BASE_PATH"
  echo "pool_path=$POOL_PATH"
  echo "testing_pool_path=$TESTING_POOL_PATH"
  echo "stable_pool_path=$STABLE_POOL_PATH"
  echo "domain=$DOMAIN"
  echo "stable_domain=$STABLE_DOMAIN"
} >> "$GITHUB_OUTPUT"
