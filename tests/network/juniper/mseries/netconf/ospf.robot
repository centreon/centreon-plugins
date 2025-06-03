*** Settings ***
Documentation       Juniper Mseries Netconf OSPF

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=ospf
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}ospf.netconf"

*** Test Cases ***
Ospf ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY}
            ...    OK: Number of OSPF neighbors detected: 2 - neighbors-changed : Buffer creation - All OSPF neighbors are ok | 'ospf.neighbors.detected.count'=2;;;0;
            ...    2     ${EMPTY}
            ...    OK: Number of OSPF neighbors detected: 2 - All OSPF neighbors are ok | 'ospf.neighbors.detected.count'=2;;;0;
