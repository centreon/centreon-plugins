#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# global errors counter
errors=0

function info() {
  echo -e "${GREEN}INFO${NC}: $*"
}

function warning() {
  echo -e "${YELLOW}WARNING${NC}: $*"
}

function error() {
  echo -e "${RED}ERROR${NC}: $*"
  : $((errors++))
}

function fatal() {
  echo -e "${RED}FATAL${NC}: $*"
  exit 1
}

jq=$(type -p jq) || fatal "Could not locate jq command"
# Determining the robotidy command
robotidy_path=$(type -p robocop) || robotidy_path=$(type -p robotidy) || fatal "Counld not locate either robocop nor robotidy. Cannot check robot lint"
robotidy_exe="${robotidy_path##*/}"
info "Robot lint tool is $robotidy_exe"
# Options depend on the use binary
declare -A robotidy_opts=([robotidy]="--check --skip-keyword-call Examples:" [robocop]="check" )
# Get list of committed files
committed_files=( $(git diff --cached --name-only --diff-filter=ACMR) )
info "Starting plugins pre-commit hooks for ${#committed_files[@]} files"
for file in "${committed_files[@]}"; do
    info "  - $file:"
    file_extension="${file##*.}"
    case "$file_extension" in
        pm|pl)
            # check that the perl file compiles
            info "      - Checking that file compiles"
            PERL5LIB="$PERL5LIB::./src/" perl -c "$file" >/dev/null 2>&1 || error "     - File $file does not compile with perl -c"
            # check the copyright year
            info "      - Checking that file copyright is OK"
            grep "Copyright $(date +%Y)" "$file" >/dev/null || error "Copyright in $file does not contain the current year"
            # check that no help is written as --warning-* --critical-*
            info "      - Checking there's no unsplitted '--warning-*' / '--critical-*'"
            grep -- '--warning-\*\|--critical-\*' "$file"  >/dev/null && error "     - File $file contains help that is written as --warning-* or --critical-*"
            # check spelling
            info "      - Checking that spelling in file is OK"
            perl .github/scripts/pod_spell_check.t "$file" ./tests/resources/spellcheck/stopwords.txt >/dev/null 2>&1 || error "Spellcheck error on file $file"
            ;;
        txt)
            if [[ "${file##*/}" == "stopwords.txt" ]]; then
                # sort file and check if it makes a difference
                info "      - Checking that stopwords.txt is sorted "
                cat "$file" | sort -ui >/tmp/sorted_stopwords
                diff "$file" /tmp/sorted_stopwords >/dev/null || error "     - stopwords.txt not sorted properly"

            fi
            ;;
        robot)
            info "      - Checking robot lint"
            $robotidy_path ${robotidy_opts[$robotidy_exe]} "$file" >/dev/null 2>&1 || warning "   - Robot lint errors found in $file"
            ;;
        json)
            info "      - Checking JSON validity"
            jq '' "$file" >/dev/null 2>&1 || error "     - JSON file $file is not valid"
          ;;
        *)
            ;;
    esac
done
(( errors > 0 )) && fatal "$errors errors found in pre-commit checks"
info "All plugins pre-commit checks done for file $file"
