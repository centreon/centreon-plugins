#!/bin/bash

if [[ -z "$1" || "$1" =~ ^--help|-h$ ]] || [[ ! "$1" =~ ^[a-z0-9:]+$ ]]; then
    echo "Usage: ${0##*/} path::to::plugin [mode] [mockoon.json]"
    echo
    echo "Prepare a robot test file for the mode passed as second argument (or all available modes if none provided)."
    echo "If the last argument ends with '.json', it is used as the Mockoon file."
    echo "Example: ${0##*/} os::linux::snmp::plugin cpu"
    echo "         ${0##*/} os::linux::snmp::plugin cpu linux.json"
    echo "         ${0##*/} os::linux::snmp::plugin linux.json"

    echo
    exit
fi

# store options
plugin="$1"
unique_mode="$2"
mockoon_file="mockoon.json"
if [[ "$unique_mode" == *.json ]]; then
    mockoon_file="$unique_mode"
    unique_mode=""
else
    if [[ "$3" == *.json ]]; then
        mockoon_file="$3"
    fi
fi

# source path is where the script is stored
source_path="${0%/*}"
# convert relative path to absolute
[[ "${source_path:0:2}" == './' ]] && source_path="${PWD}/${source_path:2}"

# load variables and functions
source "$source_path/lib/common_functions.sh"

# infer the project root path
project_path="$source_path/../.."
# include the project's Perl sources to @INC
PERL5LIB="$PERL5LIB:$project_path/src/"

base_cmd="$project_path/src/centreon_plugins.pl --plugin=$plugin"
# transform the Perl package path into file system path of the Perl code
plugin_fs_path="${plugin//:://}"
plugin_fs_path="${plugin_fs_path%/plugin*}"

$base_cmd | grep "Can't locate" >/dev/null && fatal "Plugin '$plugin' not found"

# where the tests should be located:
tests_path="$project_path/tests/${plugin_fs_path}"
mkdir -p "$tests_path"

################################################################################
# Functions that generate the robot content
################################################################################

# part that is specific to mockoon-based tests
function print_mockoon_tpl() {
  # if a custom mode is provided, use it's options in the main command definition
  if [[ "$custommode" != "" ]]; then
    cat <<EOF
Suite Setup         Start Mockoon    \${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
\${MOCKOON_JSON}     \${CURDIR}\${/}$mockoon_file
\${CMD}              \${CENTREON_PLUGINS}
...                 --plugin=$plugin
...                 --mode=$mode
EOF
    declare -A option_value=(
      [--hostname]="\${HOSTNAME}"
      [--port]="\${APIPORT}"
      [--proto]="http"
      [--username]="username"
      [--password]="password"
      [--token]="token"
      [--timeout]="10"
    )
    for option in "${custommode_options[@]}"; do
      value="${option_value[$option]}"
      [[ "$value" == "" ]] && value="${option#--}"
      echo "...                 ${option}=$value"
    done
  else
    # if no custom mode is provided (it barely happens) put default options as placeholders
    cat <<EOF
Suite Setup         Start Mockoon    \${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
\${MOCKOON_JSON}     \${CURDIR}\${/}mockoon.json
\${CMD}              \${CENTREON_PLUGINS}
...                 --plugin=$plugin
...                 --mode=$mode
...                 --hostname=\${HOSTNAME}
...                 --port=\${APIPORT}
...                 --proto=http
...                 --username=1
...                 --password=1

EOF
  fi
}

# part that is specific to snmp-based tests
function print_snmp_tpl() {
    local community="$1"

    cat <<EOF
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
\${CMD}      \${CENTREON_PLUGINS}
...        --plugin=$plugin
...        --mode=$mode
...        --hostname=\${HOSTNAME}
...        --snmp-port=\${SNMPPORT}
...        --snmp-version=\${SNMPVERSION}
...        --snmp-community=$community/snmpwalk_file_base_name
EOF
}

# main robot-generating function
function print_robot() {
    local plugin="$1" ; shift
    local mode="$1" ; shift
    local community="$1" ; shift
    local options=( "\${EMPTY}" $* )

    local only_colons="${plugin//[^:]}"
    local path_depth=$(( ${#only_colons} / 2 ))

    local slash='${/}'
    local recursive_path=
    for (( i=0 ; i < path_depth ; i++ )); do
        recursive_path="${recursive_path}..$slash"
    done
#caca
    cat <<EOF
*** Settings ***
Documentation       $plugin

Resource            \${CURDIR}\${/}${recursive_path}resources/import.resource

EOF

    if [[ "$plugin" =~ snmp ]]; then
        print_snmp_tpl "$community"
    else
        print_mockoon_tpl
    fi

    # split the plugin's perl path to pick the tags from
    local tags=( ${plugin//::/ } )
    # pick only the first two elements (category and subcategory) and the penultimate (protocol)
    # example: os::linux::snmp::plugin --> we keep 'os', 'linux' and 'snmp'
    local tags_str="${tags[0]}    ${tags[1]}    ${tags[${#tags[@]} - 2]}"
    cat <<EOF

*** Test Cases ***
${mode^} \${tc}
    [Tags]    $tags_str
    \${command}    Catenate
    ...    \${CMD}
    ...    \${extra_options}

    Ctn Run Command And Check Result As Strings    \${command}    \${expected_result}

EOF
    # init test case counter
    local tc=1
    local line_prefix='    ...    '
    echo -e "    Examples:\n${line_prefix}tc\n${line_prefix}extra_options\n${line_prefix}expected_result\n${line_prefix}--"
    for option in "${options[@]}"; do
        [[ "$option" != "\${EMPTY}" ]] && option="$option=1"
        expected_status="OK"
        [[ "$option" =~ --warning ]] && expected_status="WARNING"
        [[ "$option" =~ --critical ]] && expected_status="CRITICAL"
        echo "${line_prefix}${tc}"
        echo "${line_prefix}${option}"
        echo "${line_prefix}${expected_status}: put the real expected output here"
        # increment the test case counter
        : $((tc++))
    done
}

# generates a robot file that only checks "--mode=X --help" succeeds for every mode
# useful for plugins whose modes just wrap already-tested generic modes and don't need full functional tests
# (see tests/network/forcepoint/sdwan/snmp/standard.robot for a hand-written example of this convention)
function print_help_robot() {
    local plugin="$1" ; shift
    local modes=( "$@" )

    local only_colons="${plugin//[^:]}"
    local path_depth=$(( ${#only_colons} / 2 ))

    local slash='${/}'
    local recursive_path=
    for (( i=0 ; i < path_depth ; i++ )); do
        recursive_path="${recursive_path}..$slash"
    done

    cat <<EOF
*** Settings ***
Documentation       $plugin

Resource            \${CURDIR}\${/}${recursive_path}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
\${CMD}      \${CENTREON_PLUGINS} --plugin=$plugin


EOF

    # split the plugin's perl path to pick the tags from
    local tags=( ${plugin//::/ } )
    # pick only the first two elements (category and subcategory) and the penultimate (protocol)
    local tags_str="${tags[0]}    ${tags[1]}    ${tags[${#tags[@]} - 2]}"
    cat <<EOF
*** Test Cases ***
Standard \${tc} - \${mode}
    [Tags]    $tags_str
    \${command}    Catenate
    ...    \${CMD}
    ...    --mode=\${mode}
    ...    --help

    Ctn Run Command And Check Result As Regexp    \${command}    \${expected_result}    flags=IGNORECASE

EOF
    # init test case counter
    local tc=1
    local line_prefix='    ...    '
    echo -e "    Examples:\n${line_prefix}tc\n${line_prefix}mode\n${line_prefix}expected_result\n${line_prefix}--"
    for mode in "${modes[@]}"; do
        echo "${line_prefix}${tc}"
        echo "${line_prefix}${mode}"
        local mode_text="${mode//-/.}"
        echo "${line_prefix}Mode:\n.*${mode_text}"
        # increment the test case counter
        : $((tc++))
    done
}

# format a robot file in place so it already complies with the pre-commit robot-lint check
function format_with_robocop() {
    local file="$1"
    if [[ -n "$robocop_path" ]] ; then
        info "Formatting $file with robocop"
        "$robocop_path" format "$file"
    else
        warning "robocop not found in PATH, skipping formatting of $file"
    fi
}

robocop_path=$(type -p robocop)

# list every mode the plugin exposes: help.robot always covers all of them,
# whether or not $2 restricts the functional robot files generated below
eval $(parse_modes $base_cmd --list-mode)
all_modes=( "${modes[@]}" )

# if $2 is provided, then only this mode gets a full functional robot file generated
if [[ -n "$unique_mode" ]]; then
    $base_cmd --mode=$unique_mode | grep "UNKNOWN: mode '$unique_mode'" >/dev/null && fatal "Mode '$unique_mode' not found for plugin $plugin"
    modes=( $unique_mode )
fi

[[ $DEBUG ]] && declare -p modes all_modes

for mode in "${modes[@]}"; do
    info "Generating tests for mode $mode"
    robot_file="${tests_path}/${mode}.robot"
    # get the first custom mode

    custommode=$(get_first_custommode $base_cmd --mode=$mode --list-custommode)

    # get the list of options brought by the custommode if any
    declare -a custommode_options
    if [[ "$custommode" != "" ]] ; then
      eval $(parse_custommode_options_from_help $custommode $base_cmd --custommode=$custommode --mode=$mode --help)
      [[ $DEBUG ]] && declare -p custommode_options
    fi

    eval $(parse_threshold_options_from_help $base_cmd --custommode=$custommode --mode=$mode --help)
    [[ $DEBUG ]] && declare -p threshold_options

    # Backup the file if it already exists
    if [[ -f "$robot_file" ]] ; then
        robot_backup="${robot_file}_$(date  +%F_%H-%M-%S).${RANDOM}"
        warning "$robot_file already exists! Backing it up to $robot_backup"
        cp "$robot_file" "$robot_backup"
    fi
    info "Writing test file ${robot_file}"
    # print the robot content into the file
    print_robot "$plugin" "$mode" "$plugin_fs_path" ${threshold_options[*]} > "${tests_path}/${mode}.robot"
    format_with_robocop "$robot_file"
    unset threshold_options robot_file robot_backup
done

# also generate/refresh a help.robot checking that "--help" succeeds for every mode
help_robot_file="${tests_path}/help.robot"
if [[ -f "$help_robot_file" ]] ; then
    help_robot_backup="${help_robot_file}_$(date  +%F_%H-%M-%S).${RANDOM}"
    warning "$help_robot_file already exists! Backing it up to $help_robot_backup"
    cp "$help_robot_file" "$help_robot_backup"
fi
info "Writing test file ${help_robot_file}"
print_help_robot "$plugin" "${all_modes[@]}" > "$help_robot_file"
format_with_robocop "$help_robot_file"
unset help_robot_file help_robot_backup

info "Tests have been generated in $tests_path"
