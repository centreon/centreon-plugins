*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::extreme::snmp::plugin


*** Test Cases ***
hardware-x435-8p-4s ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/extreme/snmp/x435-8p-4s
    ...    --component=${component}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    component        extra_options                       expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}                            OK: All 4 components are ok [1/1 poes, 1/1 power supplies, 1/1 slots, 1/1 temperatures]. | 'temp'=82C;;;; 'poe_power_1'=0.000W;;;0; 'count_poe'=1;;;; 'count_psu'=1;;;; 'count_slot'=1;;;; 'count_temperature'=1;;;;
            ...      2     fan              ${EMPTY}                            CRITICAL: No components are checked.
            ...      3     psu              ${EMPTY}                            OK: All 1 components are ok [1/1 power supplies]. | 'count_psu'=1;;;;
            ...      4     slot             ${EMPTY}                            OK: All 1 components are ok [1/1 slots]. | 'count_slot'=1;;;;
            ...      5     temperature      ${EMPTY}                            OK: All 1 components are ok [1/1 temperatures]. | 'temp'=82C;;;; 'count_temperature'=1;;;;
            ...      5.1   temperature       --warning='temperature,.*,25'      WARNING: Temperature is 82 degree centigrade | 'temp'=82C;0:25;;; 'count_temperature'=1;;;;
            ...      5.2   temperature       --critical='temperature,.*,25'     CRITICAL: Temperature is 82 degree centigrade | 'temp'=82C;;0:25;; 'count_temperature'=1;;;;
            ...      6     poe              ${EMPTY}                            OK: All 1 components are ok [1/1 poes]. | 'poe_power_1'=0.000W;;;0; 'count_poe'=1;;;;
            
