*** Settings ***
Documentation       Check stack members.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::aruba::aoscx::snmp::plugin

*** Test Cases ***
stack ${tc}
    [Tags]    network    aruba
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=stack
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/aruba/aoscx/snmp/slim_aoscx-stack
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    # first run to build cache
    Run    ${command}
    # second run to control the output
    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     --verbose                                                                                               OK: All stack members are ok checking stack member 'Anonymized 018' role: active [state: standby] port '1' operational status: up [admin status: enabled] port '2' operational status: up [admin status: enabled] checking stack member 'Anonymized 042' role: active [state: member] checking stack member 'Anonymized 076' role: active [state: member] checking stack member 'Anonymized 160' role: notReady [state: commander] port '1' operational status: up [admin status: enabled] port '2' operational status: up [admin status: enabled]
            ...      2     --unknown-member-status='${PERCENT}\\{role\\} ne "notReady"'                                            UNKNOWN: Stack member 'Anonymized 018' role: active [state: standby] - Stack member 'Anonymized 042' role: active [state: member] - Stack member 'Anonymized 076' role: active [state: member]
            ...      3     --warning-member-status='${PERCENT}\\{state\\} ne "down"'                                               WARNING: Stack member 'Anonymized 018' role: active [state: standby] - Stack member 'Anonymized 042' role: active [state: member] - Stack member 'Anonymized 076' role: active [state: member] - Stack member 'Anonymized 160' role: notReady [state: commander]
            ...      4     --critical-member-status='${PERCENT}\\{role\\} eq ${PERCENT}\\{roleLast\\}'                             CRITICAL: Stack member 'Anonymized 018' role: active [state: standby] - Stack member 'Anonymized 042' role: active [state: member] - Stack member 'Anonymized 076' role: active [state: member] - Stack member 'Anonymized 160' role: notReady [state: commander]
            ...      5     --unknown-port-status='${PERCENT}\\{oper_status\\} ne "down"'                                           UNKNOWN: Stack member 'Anonymized 018' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled] - Stack member 'Anonymized 160' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled]
            ...      6     --warning-port-status='${PERCENT}\\{admin_status\\} ne "down"'                                          WARNING: Stack member 'Anonymized 018' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled] - Stack member 'Anonymized 160' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled]
            ...      7     --critical-port-status='${PERCENT}\\{oper_status\\} eq "up" and ${PERCENT}\\{display\\} ne "up"'        CRITICAL: Stack member 'Anonymized 018' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled] - Stack member 'Anonymized 160' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled]
