*** Settings ***
Documentation       Juniper Mseries Netconf CPU

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=list-bgp
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}bgp.netconf"

*** Test Cases ***
List Bgp ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extraoptions              expected_result   --
        ...      1     ${EMPTY}                  ^List BGP peers: (\\\\n\\\\[.*\\\\]){5}\\\\Z
        ...      2     --disco-show              ^\\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<label .*\\\\/\\\\>){5}\\\\n\\\\<\\\\/data\\\\>$
        ...      3     --disco-format            ^\\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<element\\\\>.*\\\\<\\\\/element\\\\>){6}\\\\n\\\\<\\\\/data\\\\>$
