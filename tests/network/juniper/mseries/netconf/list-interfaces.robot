*** Settings ***
Documentation       Juniper Mseries Netconf List Interfaces

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
...         --mode=list-interfaces
...         --hostname=${HOSTNAME}
...         --sshcli-command=get_data
...         --sshcli-path=${CURDIR}
...         --sshcli-option="-f=${CURDIR}${/}data${/}interfaces-discovery.netconf"


*** Test Cases ***
List Interface ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extraoptions              expected_result   --
        ...      1     ${EMPTY}                  ^List interfaces: (\\\\n\\\\[.*\\\\]){6}\\\\Z
        ...      2     --disco-show              ^\\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<label .*\\\\/\\\\>){6}\\\\n\\\\<\\\\/data\\\\>$
        ...      3     --disco-format            ^\\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<element\\\\>.*\\\\<\\\\/element\\\\>){5}\\\\n\\\\<\\\\/data\\\\>$
