*** Settings ***
Documentation       Hardware UPS Socomec Netvision SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=hardware::ups::socomec::netvision::snmp::plugin


*** Test Cases ***
Battery ${tc}/4
    [Tags]    hardware    ups    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=battery
    ...    --hostname=127.0.0.1
    ...    --snmp-version=2c
    ...    --snmp-port=2024
    ...    --snmp-community=hardware/ups/socomec/netvision/snmp/battery

    # Append options to command
    ${opt}    Append Option    --warning-temperature    ${w_temperature}
    ${command}    Catenate    ${command}    ${opt}
    ${opt}    Append Option    --critical-temperature    ${c_temperature}
    ${command}    Catenate    ${command}    ${opt}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    ${command} \nWrong output result for compliance of ${expected_result}{\n}Command output:{\n}${output}{\n}{\n}{\n}

    Examples:        tc    w_temperature    c_temperature    expected_result    --
            ...      1     30               50               OK: battery status is normal - charge remaining: 100% (0 minutes remaining) | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=22C;0:30;0:50;;
            ...      2     20               50               WARNING: temperature: 22 C | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=22C;0:20;0:50;;
            ...      3     10               20               CRITICAL: temperature: 22 C | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=22C;0:10;0:20;;
            ...      4     _empty_          _empty_          OK: battery status is normal - charge remaining: 100% (0 minutes remaining) | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=22C;;;;


*** Keywords ***
Append Option
    [Documentation]    Concatenates the first argument (option) with the second (value) after having replaced the value with "" if its content is '_empty_'
    [Arguments]    ${option}    ${value}
    ${value}    Set Variable If    '${value}' == '_empty_'    ''    ${value}
    RETURN    ${option}=${value}
