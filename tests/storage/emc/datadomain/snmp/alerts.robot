*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
alerts ${tc}
    [Tags]    snmp  storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=alerts
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/slim-datadomain
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                 expected_result    --
            ...      1     --truly-alert='\\\%{severity} =~ /emergency|alert|warning|critical/i'         OK: current alerts: 0 | 'alerts.current.count'=0;;;0;
            ...      2     --warning-alerts-current --critical-alerts-current                            OK: current alerts: 0 | 'alerts.current.count'=0;;;0;
            ...      3     --display-alerts                                                              OK: current alerts: 0 | 'alerts.current.count'=0;;;0;
