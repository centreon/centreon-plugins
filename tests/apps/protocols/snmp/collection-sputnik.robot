*** Settings ***
Documentation       Hardware UPS Sputnik SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=apps::protocols::snmp::plugin


*** Test Cases ***
SNMP Collection - Sputnik Environment ${tc}/3
    [Tags]    snmp collection
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=collection
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=apps/protocols/snmp/collection-sputnik
    ...    --config=${CURDIR}${/}..${/}..${/}..${/}..${/}src/contrib/collection/snmp/sputnik-environment.json

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    expected_result    --
            ...      1     OK: Sensor '1' temperature is '20.06'°C and humidity is '33'% | '1#environment.temperature.celsius'=20.06C;;;; '1#environment.humidity.percent'=33%;;;0;100
            ...      2     OK: Sensor '1' temperature is '20.06'°C and humidity is '33'% | '1#environment.temperature.celsius'=20.06C;;;; '1#environment.humidity.percent'=33%;;;0;100
            ...      3     OK: Sensor '1' temperature is '20.06'°C and humidity is '33'% | '1#environment.temperature.celsius'=20.06C;;;; '1#environment.humidity.percent'=33%;;;0;100


*** Keywords ***
Append Option
    [Documentation]    Concatenates the first argument (option) with the second (value) after having replaced the value with "" if its content is '_empty_'
    [Arguments]    ${option}    ${value}
    ${value}    Set Variable If    '${value}' == '_empty_'    ''    ${value}
    RETURN    ${option}=${value}
