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

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY}
            ...    OK: Number of OSPF neighbors detected: 2 - neighbors-changed : Buffer creation - All OSPF neighbors are ok | 'ospf.neighbors.detected.count'=2;;;0;
            ...    2     ${EMPTY}
            ...    OK: Number of OSPF neighbors detected: 2 - All OSPF neighbors are ok | 'ospf.neighbors.detected.count'=2;;;0;
            ...    3     --filter-neighbor-address='10.100.25.119'
            ...    OK: Number of OSPF neighbors detected: 1 - neighbors-changed : Buffer creation - neighbor address '10.100.25.119' [interface: ae0.0] state: Full | 'ospf.neighbors.detected.count'=1;;;0;
            ...    4     --unknown-neighbors-changed='\\\%{detectedLast} >= 1'
            ...    UNKNOWN: Neighbors current: 2 (last: 2) | 'ospf.neighbors.detected.count'=2;;;0;
            ...    5     --warning-neighbors-changed='\\\%{detected} >= 1'
            ...    WARNING: Neighbors current: 2 (last: 2) | 'ospf.neighbors.detected.count'=2;;;0;
            ...    6     --critical-neighbors-changed='\\\%{detectedLast} - \\\%{detected} == 0'
            ...    CRITICAL: Neighbors current: 2 (last: 2) | 'ospf.neighbors.detected.count'=2;;;0;
            ...    7     --unknown-neighbor-status='\\\%{interfaceName} eq "ae1.0"'
            ...    UNKNOWN: neighbor address '10.100.25.121' [interface: ae1.0] state: Full | 'ospf.neighbors.detected.count'=2;;;0;
            ...    8     --warning-neighbor-status='\\\%{address} eq "10.100.25.119"'
            ...    WARNING: neighbor address '10.100.25.119' [interface: ae0.0] state: Full | 'ospf.neighbors.detected.count'=2;;;0;
            ...    9     --critical-neighbor-status='\\\%{state} eq "Full"'
            ...    CRITICAL: neighbor address '10.100.25.119' [interface: ae0.0] state: Full - neighbor address '10.100.25.121' [interface: ae1.0] state: Full | 'ospf.neighbors.detected.count'=2;;;0;
            ...    10    --warning-neighbors-detected=1
            ...    WARNING: Number of OSPF neighbors detected: 2 | 'ospf.neighbors.detected.count'=2;0:1;;0;
            ...    11    --critical-neighbors-detected=1
            ...    CRITICAL: Number of OSPF neighbors detected: 2 | 'ospf.neighbors.detected.count'=2;;0:1;0;
