*** Settings ***
Documentation       

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::wlc::snmp::plugin


*** Test Cases ***
radius-acc-servers ${tc}
    [Tags]    network    wlc    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=radius-acc-servers
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=2024
    ...    --snmp-community=network/cisco/wlc/snmp/slim_cisco_wlc
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --verbose                                                             UNKNOWN: Can't construct cache...