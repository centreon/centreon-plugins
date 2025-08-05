*** Settings ***
Documentation       Juniper Mseries Netconf List Disks

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=list-disks
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}disk.netconf"

*** Test Cases ***
List-Disks ${tc}
    [Documentation]    Check list-devices results
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}
    Ctn Run Command Without Connector And Check Result As Regexp    ${tc}    ${command}    ${expected_result}

    Examples:    tc    extraoptions              expected_result   --
        ...      1     ${EMPTY}                  ^List disks: (\\\\n\\\\[.*\\\\]){5}\\\\Z
        ...      2     --disco-show              ^\\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<label .*\\\\/\\\\>){5}\\\\n\\\\<\\\\/data\\\\>$
        ...      3     --disco-format            ^\\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<element\\\\>.*\\\\<\\\\/element\\\\>){2}\\\\n\\\\<\\\\/data\\\\>$
