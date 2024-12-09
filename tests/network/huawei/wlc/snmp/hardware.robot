*** Settings ***
Documentation       Check Huawei equipments in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::standard::snmp::plugin


*** Test Cases ***
hardware ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                             expected_result    --
            ...      1     --threshold-overload='fan,WARNING,abnormal'               OK: All 0 components are ok [].
            ...      2     --reload-cache-time='-1'                                  OK: All 0 components are ok []. 
            ...      3     --warning='fan,.*,40'                                     OK: All 0 components are ok [].
            ...      4     --warning='temperature,.*,40'                             OK: All 0 components are ok [].
            ...      5     --critical='fan,.*,45'                                    OK: All 0 components are ok []. 
            ...      6     --critical='temperature,.*,45'                            OK: All 0 components are ok [].
            ...      7     --verbose                                                 OK: All 0 components are ok []. checking fans checking temperatures
            ...      8     --no-component                                            CRITICAL: No components are checked.
            ...      9     --absent-problem                                          OK: All 0 components are ok [].
            ...      10    --filter=fan,1.0                                          OK: All 0 components are ok [].
            ...      11    --component='.*'                                          OK: All 0 components are ok [].
