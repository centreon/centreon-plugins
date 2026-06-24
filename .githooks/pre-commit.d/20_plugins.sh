#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# global errors counter
errors=0
tmpfile="/tmp/check$$"

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

function check_tabs_crlf() {
    local file="$1"
    info "--> Checking BASH indentation"
    grep -P '^\t' "$file" >/dev/null 2>&1 && warning "--> File $file contains leading tab character (suspected bad indentation)."
    info "--> Checking carriage returns"
    grep $'\r' "$file" >/dev/null 2>&1 && warning "--> File $file contains CRLF line terminators."
}

function check_constants() {
    local file="$1"

    info "--> Checking constants utilization"

    grep -nH -- "-\(1\|2\|10\)[[:space:]]*=>[[:space:]]*1" "$file" > "$tmpfile"
    grep -nH "\<type[[:space:]]*=>[[:space:]]*[0-9]" "$file" >> "$tmpfile"
    if [ -s "$tmpfile" ] ; then
        error "It seems that some counters are not using constants defined in centreon/plugins/constants.pm."
        cat $tmpfile
    fi
}

function check_md5() {
    local file="$1"

    info "--> Checking MD5 utilization"
    grep -q md5_hex "$file"
    if [ $? -eq 0 ] ; then
        error "$file: It seems that md5_hexa is used. Use sha256_hex (with Digest::SHA) instead."
    fi
}

jq=$(type -p jq) || fatal "Could not locate jq command"
# Determining the robotidy command
robocop_path=$(type -p robocop)

# Get list of committed files
mapfile -t committed_files < <(git diff --cached --name-only --diff-filter=ACMR)
info "Starting plugins pre-commit hooks for ${#committed_files[@]} files"
for file in "${committed_files[@]}"; do
    info "--> $file:"
    file_extension="${file##*.}"
    case "$file_extension" in
        pm|pl)
            # check that the perl file compiles
            info "--> Checking that file compiles"
            perl -I ./src -I ./tests/connectors/vmware -I ./connectors/vmware/src -c "$file" >/dev/null 2>&1 || error "File $file does not compile with perl -c"
            # check the copyright year
            info "--> Checking that file copyright is OK"
            grep "Copyright 20..-Present Centreon" "$file" >/dev/null || error "Copyright in $file does not contain \"Copyright $(date +%Y)-Present Centreon\""
            # check that no help is written as --warning-* --critical-*
            info "--> Checking there's no unsplitted '--warning-*' / '--critical-*'"
            grep -- '--warning-\*\|--critical-\*' "$file"  >/dev/null && error "File $file contains help that is written as --warning-* or --critical-*"
            # check spelling
            info "--> Checking that spelling in file is OK"
            perl .github/scripts/pod_spell_check.t "$file" ./tests/resources/spellcheck/stopwords.txt >$tmpfile 2>&1
            rc=$?
            if [ $rc -ne 0 ] ; then
                error "Spellcheck error on file $file"
                tail -n 2 $tmpfile | head -n 1 | sed 's/^[^:]*:/Invalid words:/' 2>/dev/null
            fi
            check_tabs_crlf "$file"
            check_constants "$file"
            check_md5 "$file"
            ;;
        txt)
            if [[ "${file##*/}" == "stopwords.txt" ]]; then
                # sort file and check if it makes a difference
                info "--> Checking that stopwords.txt is sorted "
                sort -ui "$file" >/tmp/sorted_stopwords
                diff "$file" /tmp/sorted_stopwords >/dev/null || error "stopwords.txt not sorted properly"
            fi
            ;;
        robot)
            info "--> Checking robot format"
            if [[ -z "$robocop_path" ]] ; then
                fatal "Could not locate robocop. Cannot check robot lint"
            fi
            check_tabs_crlf "$file"
            cp "$file" "$tmpfile" && $robocop_path format "$tmpfile" >/dev/null 2>&1
            diff -q "$file" "$tmpfile" >/dev/null 2>&1
            rc=$?
            if [ $rc -ne 0 ] ; then
                error "$file not is properly formatted, please use 'robocop format'"
            fi
            ;;
        sh)
            check_tabs_crlf "$file"
          ;;
        json)
            info "--> Checking JSON validity"
            jq '.' "$file" >/dev/null 2>&1 || error "JSON file $file is not valid"
            check_tabs_crlf "$file"
          ;;
        *)
            info "File extension '.${file_extension}' has no checks"
            ;;
    esac
done
rm -f "$tmpfile"

(( errors > 0 )) && fatal "$errors errors found in pre-commit checks"
info "All plugins pre-commit checks passed"
