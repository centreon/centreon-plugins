*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::nortel::standard::snmp::plugin


*** Test Cases ***
hardware-4950gts ${tc}
    [Tags]    network    snmp
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/4950gts-pwr
    ...    --component=${component}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    component        extra_options     expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}          OK: All 13 components are ok [12/12 entities, 1/1 temperatures]. | '5.10.0#hardware.temperature.celsius'=43.50C;;;; 'hardware.entity.count'=12;;;; 'hardware.temperature.count'=1;;;;
            ...      2     fan              ${EMPTY}          CRITICAL: No components are checked.
            ...      3     psu              ${EMPTY}          CRITICAL: No components are checked.
            ...      4     card             ${EMPTY}          CRITICAL: No components are checked.
            ...      5     entity           ${EMPTY}          OK: All 12 components are ok [12/12 entities]. | 'hardware.entity.count'=12;;;;
            ...      6     led              ${EMPTY}          CRITICAL: No components are checked.
            ...      7     temperature      ${EMPTY}          OK: All 1 components are ok [1/1 temperatures]. | '5.10.0#hardware.temperature.celsius'=43.50C;;;; 'hardware.temperature.count'=1;;;;
