# Shared helpers for the git hooks in pre-commit.d/ and pre-push.d/.
#
# Not executable and not a hook itself: source it from a hook script with
#
#   script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${script_dir}/../lib/common.sh"
#
# It deliberately sets no shell option, so that each hook keeps control of its
# own 'set -e' policy.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# global errors counter, incremented by error()
errors=0

info() {
  echo -e "${GREEN}INFO${NC}: $*"
}

warning() {
  echo -e "${YELLOW}WARNING${NC}: $*"
}

# Report a problem and keep going, so that one run reports every issue at once.
# The caller is expected to turn a non-zero 'errors' into a fatal() at the end.
error() {
  echo -e "${RED}ERROR${NC}: $*"
  errors=$((errors + 1))
}

# Report a problem and give up immediately, aborting the commit or the push.
fatal() {
  echo -e "${RED}FATAL${NC}: $*"
  exit 1
}
