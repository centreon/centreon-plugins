*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::smallbusiness::standard::snmp::plugin


*** Test Cases ***
stac ${tc}
    [Tags]    network    stack    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=stack
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=network/cisco/smallbusiness/snmp/stack
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                     expected_result    --
            ...      1     ${EMPTY}                                                                          OK: Number of members detected: 2 - All stack members are ok | 'stack.members.detected.count'=2;;;0; 'stack.member.connected.members.count'=1;;;0; 'stack.member.connected.members.count'=1;;;0;
            ...      2     --warning-member-connection-status=1                                              WARNING: stack member 'ec:02:d5:6f:49:96' [unit: 1] 'left' side connection is connected to unit '2' - 'right' side connection is notConnected - stack member 'ec:02:d5:6f:4b:17' [unit: 2] 'left' side connection is connected to unit '1' - 'right' side connection is notConnected | 'stack.members.detected.count'=2;;;0; 'stack.member.connected.members.count'=1;;;0; 'stack.member.connected.members.count'=1;;;0;
            ...      3     --critical-member-connection-status=1                                             CRITICAL: stack member 'ec:02:d5:6f:49:96' [unit: 1] 'left' side connection is connected to unit '2' - 'right' side connection is notConnected - stack member 'ec:02:d5:6f:4b:17' [unit: 2] 'left' side connection is connected to unit '1' - 'right' side connection is notConnected | 'stack.members.detected.count'=2;;;0; 'stack.member.connected.members.count'=1;;;0; 'stack.member.connected.members.count'=1;;;0;
            ...      4     --warning-members-detected=1 --critical-members-detected=2                        WARNING: Number of members detected: 2 | 'stack.members.detected.count'=2;0:1;0:2;0; 'stack.member.connected.members.count'=1;;;0; 'stack.member.connected.members.count'=1;;;0;
            ...      5     --warning-member-connected-members='' --critical-member-connected-members=0       CRITICAL: stack member 'ec:02:d5:6f:49:96' [unit: 1] number of connected members: 1 - stack member 'ec:02:d5:6f:4b:17' [unit: 2] number of connected members: 1 | 'stack.members.detected.count'=2;;;0; 'stack.member.connected.members.count'=1;;0:0;0; 'stack.member.connected.members.count'=1;;0:0;0;
