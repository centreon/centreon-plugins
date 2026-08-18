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
case "$DISTRIB_FAMILY" in
  el | el[0-9]*)
    FAMILY_PREFIX="rpm-"
    DISTRIB_FAMILY="el"
    ;;
  debian) FAMILY_PREFIX="apt-" ;;
  ubuntu) FAMILY_PREFIX="ubuntu-" ;;
  *)
    echo "::error::Unsupported distribution family: $DISTRIB_FAMILY"
    exit 1
    ;;
esac

ROOT_REPO="${FAMILY_PREFIX}${REPO_BASE}"

# business (paid) rpm content is served under an opaque path segment, mirroring
# the Artifactory layout; only rpm business repos use it (deb business does not).
BUSINESS_HASH="1a97ff9985262bf3daf7a0919f9c59a6"
HASH_SEGMENT=""
if [[ "$REPO_BASE" == "business" && "$DISTRIB_FAMILY" == "el" ]]; then
  HASH_SEGMENT="/$BUSINESS_HASH"
fi

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
TESTING_REPOSITORY_PREFIX=""
TESTING_BASE_PATH_PREFIX=""
STABLE_REPOSITORY_PREFIX=""
STABLE_BASE_PATH_PREFIX=""
REPOSITORY_NAME=""
BASE_PATH=""
SUITE=""
TESTING_SUITE=""
STABLE_SUITE=""
POOL_PATH=""
TESTING_POOL_PATH=""
STABLE_POOL_PATH=""

if [[ "$REPO_BASE" == "plugins" ]]; then
  # plugins repositories are not versioned and use their own testing layout: a
  # bare "testing" segment for releases and "testing-hotfix" for hotfixes,
  # mirroring the artifactory rpm-plugins/<distrib>/<stability> layout. deb
  # plugins share one apt-plugins/ubuntu-plugins repo with <distrib>-<stability>
  # suites.
  if [[ "$DELIVERY_TYPE" == "feature" ]]; then
    echo "::notice::Feature delivery is not supported for plugins packages, skipping delivery."
    echo "skip_delivery=true" >> "$GITHUB_OUTPUT"
    exit 0
  fi

  TESTING_SEGMENT="testing"
  TESTING_POOL_SEGMENT="testing"
  if [[ "$RELEASE_TYPE" == "hotfix" ]]; then
    TESTING_SEGMENT="testing-hotfix"
    TESTING_POOL_SEGMENT="testing/hotfix"
  fi

  STABILITY_SEGMENT="$STABILITY"
  POOL_SEGMENT="$STABILITY"
  if [[ "$STABILITY" == "testing" ]]; then
    STABILITY_SEGMENT="$TESTING_SEGMENT"
    POOL_SEGMENT="$TESTING_POOL_SEGMENT"
  fi

  if [[ "$DISTRIB_FAMILY" == "el" ]]; then
    REPOSITORY_PREFIX="$ROOT_REPO-$DISTRIB-$STABILITY_SEGMENT"
    BASE_PATH_PREFIX="$ROOT_REPO/$DISTRIB/$STABILITY_SEGMENT"
    TESTING_REPOSITORY_PREFIX="$ROOT_REPO-$DISTRIB-$TESTING_SEGMENT"
    TESTING_BASE_PATH_PREFIX="$ROOT_REPO/$DISTRIB/$TESTING_SEGMENT"
    STABLE_REPOSITORY_PREFIX="$ROOT_REPO-$DISTRIB-stable"
    STABLE_BASE_PATH_PREFIX="$ROOT_REPO/$DISTRIB/stable"
  else
    REPOSITORY_NAME="$ROOT_REPO"
    BASE_PATH="$ROOT_REPO"
    SUITE="$DISTRIB-$STABILITY_SEGMENT"
    TESTING_SUITE="$DISTRIB-$TESTING_SEGMENT"
    # stable lives in a DEDICATED repository with plain-codename suites, so
    # the client apt configuration stays identical to the artifactory one
    # (deb .../apt-plugins-stable <codename> main)
    STABLE_REPOSITORY_NAME="$ROOT_REPO-stable"
    STABLE_BASE_PATH="$ROOT_REPO-stable"
    STABLE_SUITE="$DISTRIB"
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

  REPOSITORY_PREFIX="$ROOT_REPO-feature-$FEATURE_TICKET-$VERSION-$DISTRIB-$STABILITY"
  BASE_PATH_PREFIX="$ROOT_REPO-feature$HASH_SEGMENT/$FEATURE_TICKET/$VERSION/$DISTRIB/$STABILITY"
else
  if [[ "$IS_CLOUD" == "true" || "$REPOSITORY_TYPE" == *-internal ]]; then
    ROOT_REPO="$ROOT_REPO-internal"
  fi

  if [[ "$DISTRIB_FAMILY" == "el" ]]; then
    REPOSITORY_PREFIX="$ROOT_REPO-$VERSION-$DISTRIB-$STABILITY_SEGMENT"
    BASE_PATH_PREFIX="$ROOT_REPO$HASH_SEGMENT/$VERSION/$DISTRIB/$STABILITY_SEGMENT"
    TESTING_REPOSITORY_PREFIX="$ROOT_REPO-$VERSION-$DISTRIB-$TESTING_SEGMENT"
    TESTING_BASE_PATH_PREFIX="$ROOT_REPO$HASH_SEGMENT/$VERSION/$DISTRIB/$TESTING_SEGMENT"
    STABLE_REPOSITORY_PREFIX="$ROOT_REPO-$VERSION-$DISTRIB-stable"
    STABLE_BASE_PATH_PREFIX="$ROOT_REPO$HASH_SEGMENT/$VERSION/$DISTRIB/stable"
  else
    REPOSITORY_NAME="$ROOT_REPO"
    BASE_PATH="$ROOT_REPO"
    SUITE="$DISTRIB-$VERSION-$STABILITY_SEGMENT"
    TESTING_SUITE="$DISTRIB-$VERSION-$TESTING_SEGMENT"
    # stable is a dedicated repository (its own Domain, standard-stable/business-stable,
    # is the write-protection boundary), but shares its NAME with the non-stable one --
    # Pulp scopes name uniqueness per Domain, and the Domain already says "stable", so
    # there's no need to also repeat that (or the version) in the repository name: the
    # version lives in the suite name only, like the non-stable suites above.
    STABLE_REPOSITORY_NAME="$ROOT_REPO"
    STABLE_BASE_PATH="$ROOT_REPO"
    STABLE_SUITE="$DISTRIB-$VERSION"
    POOL_PATH="pool/$VERSION/$POOL_SEGMENT/$MODULE_NAME"
    TESTING_POOL_PATH="pool/$VERSION/$TESTING_POOL_SEGMENT/$MODULE_NAME"
    STABLE_POOL_PATH="pool/$VERSION/stable/$MODULE_NAME"
  fi
fi

# unless a dedicated stable repository was selected above, stable shares the
# delivery repository
STABLE_REPOSITORY_NAME="${STABLE_REPOSITORY_NAME:-$REPOSITORY_NAME}"
STABLE_BASE_PATH="${STABLE_BASE_PATH:-$BASE_PATH}"

# one Pulp Domain per edition/channel; "-internal"/cloud repos share the
# domain of their non-internal sibling, so REPO_BASE alone is enough
DOMAIN="$REPO_BASE"
# stable is always a separate repository object, never a suite inside
# testing's, so it gets its own "-stable" domain
STABLE_DOMAIN="$REPO_BASE-stable"

echo "[DEBUG] - repository_type: $REPOSITORY_TYPE"
echo "[DEBUG] - root_repo: $ROOT_REPO"
echo "[DEBUG] - repository_prefix: $REPOSITORY_PREFIX"
echo "[DEBUG] - base_path_prefix: $BASE_PATH_PREFIX"
echo "[DEBUG] - testing_repository_prefix: $TESTING_REPOSITORY_PREFIX"
echo "[DEBUG] - testing_base_path_prefix: $TESTING_BASE_PATH_PREFIX"
echo "[DEBUG] - stable_repository_prefix: $STABLE_REPOSITORY_PREFIX"
echo "[DEBUG] - stable_base_path_prefix: $STABLE_BASE_PATH_PREFIX"
echo "[DEBUG] - repository_name: $REPOSITORY_NAME"
echo "[DEBUG] - base_path: $BASE_PATH"
echo "[DEBUG] - suite: $SUITE"
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
  echo "testing_repository_prefix=$TESTING_REPOSITORY_PREFIX"
  echo "testing_base_path_prefix=$TESTING_BASE_PATH_PREFIX"
  echo "stable_repository_prefix=$STABLE_REPOSITORY_PREFIX"
  echo "stable_base_path_prefix=$STABLE_BASE_PATH_PREFIX"
  echo "repository_name=$REPOSITORY_NAME"
  echo "base_path=$BASE_PATH"
  echo "suite=$SUITE"
  echo "testing_suite=$TESTING_SUITE"
  echo "stable_suite=$STABLE_SUITE"
  echo "stable_repository_name=$STABLE_REPOSITORY_NAME"
  echo "stable_base_path=$STABLE_BASE_PATH"
  echo "pool_path=$POOL_PATH"
  echo "testing_pool_path=$TESTING_POOL_PATH"
  echo "stable_pool_path=$STABLE_POOL_PATH"
  echo "domain=$DOMAIN"
  echo "stable_domain=$STABLE_DOMAIN"
} >> "$GITHUB_OUTPUT"
