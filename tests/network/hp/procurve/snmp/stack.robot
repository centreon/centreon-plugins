*** Settings ***
Documentation       Check stack members.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Cleanup Cache

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::hp::procurve::snmp::plugin


*** Test Cases ***
stack ${tc}
    [Tags]    network    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=stack
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/hp/procurve/snmp/slim_procurve_stack
    ...    --snmp-timeout=1
    ...    ${extra_options} | tr -d '\n' | sed -E 's/\\\\s+/ /g'
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     --verbose                                                                                               OK: All stack members are ok checking stack member 'Anonymized 238' member-status : buffer creation port '1' operational status: up [admin status: enabled] port '2' operational status: up [admin status: enabled]checking stack member 'Anonymized 239' member-status : buffer creation port '1' operational status: up [admin status: enabled] port '2' operational status: up [admin status: enabled]
            ...      2     --unknown-member-status='\\\%{role} eq "notReady"'                                                      UNKNOWN: Stack member 'Anonymized 239' role: notReady [state: commander] 
            ...      3     --warning-member-status='\\\%{state} ne "down"'                                                         WARNING: Stack member 'Anonymized 238' role: active [state: standby] - Stack member 'Anonymized 239' role: notReady [state: commander] 
            ...      4     --critical-member-status='\\\%{role} ne \\\%{roleLast}'                                                 CRITICAL: Stack member 'Anonymized 238' role: active [state: standby] - Stack member 'Anonymized 239' role: notReady [state: commander]
            ...      5     --unknown-port-status='\\\%{oper_status} eq "up"'                                                       UNKNOWN: Stack member 'Anonymized 238' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled] - Stack member 'Anonymized 239' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled]
            ...      6     --warning-port-status='\\\%{oper_status} eq "up"'                                                       WARNING: Stack member 'Anonymized 238' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled] - Stack member 'Anonymized 239' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled]
            ...      7     --critical-port-status='\\\%{oper_status} eq "up" and \\\%{display} ne "up"'                            CRITICAL: Stack member 'Anonymized 238' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled] - Stack member 'Anonymized 239' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled]
