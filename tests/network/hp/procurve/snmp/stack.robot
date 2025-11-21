*** Settings ***
Documentation       Check stack members.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


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
    ...    ${extra_options}

    # first run to build cache
    Run    ${command}
    # second run to control the output
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     --verbose                                                                                               OK: All stack members are ok ${\n}checking stack member 'Anonymized 238'${\n}${SPACE}${SPACE}${SPACE}${SPACE}role: active [state: standby]${\n}${SPACE}${SPACE}${SPACE}${SPACE}port '1' operational status: up [admin status: enabled]${\n}${SPACE}${SPACE}${SPACE}${SPACE}port '2' operational status: up [admin status: enabled]${\n}checking stack member 'Anonymized 239'${\n}${SPACE}${SPACE}${SPACE}${SPACE}role: notReady [state: commander]${\n}${SPACE}${SPACE}${SPACE}${SPACE}port '1' operational status: up [admin status: enabled]${\n}${SPACE}${SPACE}${SPACE}${SPACE}port '2' operational status: up [admin status: enabled]
            ...      2     --unknown-member-status='${PERCENT}\\{role\\} ne "notReady"'                                            UNKNOWN: Stack member 'Anonymized 238' role: active [state: standby]
            ...      3     --warning-member-status='${PERCENT}\\{state\\} ne "down"'                                               WARNING: Stack member 'Anonymized 238' role: active [state: standby] - Stack member 'Anonymized 239' role: notReady [state: commander]
            ...      4     --critical-member-status='${PERCENT}\\{role\\} eq ${PERCENT}\\{roleLast\\}'                             CRITICAL: Stack member 'Anonymized 238' role: active [state: standby] - Stack member 'Anonymized 239' role: notReady [state: commander]
            ...      5     --unknown-port-status='${PERCENT}\\{oper_status\\} eq "up"'                                             UNKNOWN: Stack member 'Anonymized 238' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled] - Stack member 'Anonymized 239' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled]
            ...      6     --warning-port-status='${PERCENT}\\{oper_status\\} eq "up"'                                             WARNING: Stack member 'Anonymized 238' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled] - Stack member 'Anonymized 239' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled]
            ...      7     --critical-port-status='${PERCENT}\\{oper_status\\} eq "up" and ${PERCENT}\\{display\\} ne "up"'        CRITICAL: Stack member 'Anonymized 238' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled] - Stack member 'Anonymized 239' port '1' operational status: up [admin status: enabled] - port '2' operational status: up [admin status: enabled]
