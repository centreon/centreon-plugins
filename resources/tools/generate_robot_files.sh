#!/bin/bash
if [[ -z "$1" || "$1" =~ ^--help|-h$ ]] || [[ ! "$1" =~ ^[a-z0-9:]+$ ]]; then
    echo -e "Usage: ${0##*/} path::to::plugin [mode]\n"
    exit
fi

# store options
plugin="$1"
unique_mode="$2"

# source path is where the script is stored
source_path="${0%/*}"
# convert relative path to absolute
[[ "${source_path:0:2}" == './' ]] && source_path="${PWD}/${source_path:2}"

# load variables and functions
source "$source_path/lib/common_functions.sh"

# infer the project root path
project_path="$source_path/../.."
# include the project's Perl sources to @INC
PERL5LIB="$PERL5LIB::$project_path/src/"

base_cmd="$project_path/src/centreon_plugins.pl --plugin=$plugin"
# transform the Perl package path into file system path of the Perl code
plugin_fs_path="${plugin//:://}"
plugin_fs_path="${plugin_fs_path%plugin*}"
# where the tests should be located:
tests_path="$project_path/tests/${plugin_fs_path}"
mkdir -p "$tests_path"

################################################################################
# Functions that generate the robot content
################################################################################

# part that is specific to mockoon-based tests
function print_mockoon_tpl() {
    cat <<EOF
Suite Setup         Start Mockoon    \${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
\${MOCKOON_JSON}     \${CURDIR}\${/}mockoon.json
\${CMD}              \${CENTREON_PLUGINS}
...         --plugin=$plugin
...         --mode=$mode
...         --hostname=\${HOSTNAME}
...         --port=\${APIPORT}

EOF
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
...         --plugin=$plugin
...         --mode=$mode
...         --hostname=\${HOSTNAME}
...         --snmp-port=\${SNMPPORT}
...         --snmp-community=$community/TO_BE_COMPLETED

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
        echo "${line_prefix}${tc}"
        echo "${line_prefix}${option}"
        echo "${line_prefix}OK"
        # increment the test case counter
        : $((tc++))
    done
}


# if $2 is provided, then only this mode will be tested
if [[ -n "$unique_mode" ]]; then
    modes=( $unique_mode )
else
    # if no $2, list all the plugin's modes: eval will evaluate the declaration returned by parse_modes
    eval $(parse_modes $base_cmd --list-mode)
    # now we have an array of available modes in the variable named "modes"
fi
[[ $DEBUG ]] && declare -p modes

for mode in "${modes[@]}"; do
    info "Generating tests for mode $mode"
    # get the list of options in variable threshold_options
    eval $(parse_threshold_options_from_help $base_cmd --mode=$mode --help)
    [[ $DEBUG ]] && declare -p threshold_options

    # print the robot content into the file
    print_robot "$plugin" "$mode" "$plugin_fs_path" ${threshold_options[*]} > "${tests_path}/${mode}.robot"
    unset threshold_options
done
info "Tests have been generated in $tests_path"
