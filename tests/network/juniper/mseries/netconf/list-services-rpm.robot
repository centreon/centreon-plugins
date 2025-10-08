*** Settings ***
Documentation       Juniper Mseries Netconf List Services RPM

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=list-services-rpm
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}services_rpm.netconf"

*** Test Cases ***
List Service Rpm ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extraoptions              expected_result   --
        ...      1     ${EMPTY}                  ^List services RPM: (\\\\n\\\\[.*\\\\]){2}\\\\Z
        ...      2     --disco-show              ^\\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<label .*\\\\/\\\\>){2}\\\\n\\\\<\\\\/data\\\\>$
        ...      3     --disco-format            ^\\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<element\\\\>.*\\\\<\\\\/element\\\\>){5}\\\\n\\\\<\\\\/data\\\\>$
