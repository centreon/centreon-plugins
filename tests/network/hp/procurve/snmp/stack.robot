*** Settings ***
Documentation       Check stack members.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

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
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     --verbose                                                                                               OK: All stack members are ok ${Space}checking stack member 'Anonymized 238'${Space}role: active [state: standby]${Space}port '1' operational status: up [admin status: enabled]${Space}port '2' operational status: up [admin status: enabled]${Space}checking stack member 'Anonymized 239'${Space}role: notReady [state: commander]${Space}port '1' operational status: up [admin status: enabled]${Space}port '2' operational status: up [admin status: enabled]
            ...      2     --unknown-member-status=''                                                                              OK: All stack members are ok
            ...      3     --warning-member-status=''                                                                              OK: All stack members are ok
            ...      4     --critical-member-status='\\\%{role} ne \\\%{roleLast}'                                                 OK: All stack members are ok
            ...      5     --unknown-port-status=''                                                                                OK: All stack members are ok
            ...      6     --warning-port-status=''                                                                                OK: All stack members are ok
            ...      7     --critical-port-status='\\\%{admin_status} eq "up" and \\\%{oper_status} ne "up"'                       OK: All stack members are ok