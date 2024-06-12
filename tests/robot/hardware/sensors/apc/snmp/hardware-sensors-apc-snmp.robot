*** Settings ***
Documentation       Hardware Sensors APC SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=hardware::sensors::apc::snmp::plugin --mode=sensors --hostname=127.0.0.1 --snmp-version=2c --snmp-port=2024


*** Test Cases ***
APC Sensors ${tc}/9
    [Tags]    hardware    sensors    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/sensors/apc/snmp/sensors

    # Append options to command
    ${command}    Append Option To Command    ${command}    --warning    ${warning}
    ${command}    Append Option To Command    ${command}    --critical    ${critical}
    ${command}    Append Option To Command    ${command}    --component    ${component}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for compliance of ${expected_result}{\n}Command output:{\n}${output}{\n}{\n}{\n}
# --component 'temperature' --warning='humidity,.,45:65' --critical='humidity,.,35:70'
    Examples:        tc    component      warning                 critical               expected_result    --
            ...      1     _empty_        _empty_                 _empty_                OK: All 2 components are ok [2/2 temperatures]. | 'Main Module:Sonde de temperature#hardware.sensor.temperature.celsius'=23C;;;; 'Main Module:Sonde de temperature#hardware.sensor.humidity.percentage'=35%;;;0;100 'hardware.temperature.count'=2;;;;
            ...      2     _empty_        humidity,.,45:65        _empty_                WARNING: Humidity 'Main Module:Sonde de temperature' is 35 % | 'Main Module:Sonde de temperature#hardware.sensor.temperature.celsius'=23C;;;; 'Main Module:Sonde de temperature#hardware.sensor.humidity.percentage'=35%;45:65;;0;100 'hardware.temperature.count'=2;;;;
            ...      3     _empty_        humidity,.,45:65        humidity,.,35:70       WARNING: Humidity 'Main Module:Sonde de temperature' is 35 % | 'Main Module:Sonde de temperature#hardware.sensor.temperature.celsius'=23C;;;; 'Main Module:Sonde de temperature#hardware.sensor.humidity.percentage'=35%;45:65;35:70;0;100 'hardware.temperature.count'=2;;;;
            ...      4     _empty_        _empty_                 _empty_                OK: All 2 components are ok [2/2 temperatures]. | 'Main Module:Sonde de temperature#hardware.sensor.temperature.celsius'=23C;;;; 'Main Module:Sonde de temperature#hardware.sensor.humidity.percentage'=35%;;;0;100 'hardware.temperature.count'=2;;;;
            ...      5     _empty_        humidity,.,45:65        _empty_                WARNING: Humidity 'Main Module:Sonde de temperature' is 35 % | 'Main Module:Sonde de temperature#hardware.sensor.temperature.celsius'=23C;;;; 'Main Module:Sonde de temperature#hardware.sensor.humidity.percentage'=35%;45:65;;0;100 'hardware.temperature.count'=2;;;;
            ...      6     _empty_        humidity,.,45:65        humidity,.,35:70       WARNING: Humidity 'Main Module:Sonde de temperature' is 35 % | 'Main Module:Sonde de temperature#hardware.sensor.temperature.celsius'=23C;;;; 'Main Module:Sonde de temperature#hardware.sensor.humidity.percentage'=35%;45:65;35:70;0;100 'hardware.temperature.count'=2;;;;
            ...      7     .*             _empty_                 _empty_                OK: All 2 components are ok [2/2 temperatures]. | 'Main Module:Sonde de temperature#hardware.sensor.temperature.celsius'=23C;;;; 'Main Module:Sonde de temperature#hardware.sensor.humidity.percentage'=35%;;;0;100 'hardware.temperature.count'=2;;;;
            ...      8     _empty_        temperature,.,22:25     temperature,.,22:25    OK: All 2 components are ok [2/2 temperatures]. | 'Main Module:Sonde de temperature#hardware.sensor.temperature.celsius'=23C;22:25;22:25;; 'Main Module:Sonde de temperature#hardware.sensor.humidity.percentage'=35%;;;0;100 'hardware.temperature.count'=2;;;;
            ...      9     _empty_        _empty_                 _empty_                OK: All 2 components are ok [2/2 temperatures]. | 'Main Module:Sonde de temperature#hardware.sensor.temperature.celsius'=23C;;;; 'Main Module:Sonde de temperature#hardware.sensor.humidity.percentage'=35%;;;0;100 'hardware.temperature.count'=2;;;;


*** Keywords ***
Append Option To Command
    [Documentation]    Concatenates the first argument (option) with the second (value) after having replaced the value with "" if its content is '_empty_'
    [Arguments]    ${cmd}    ${option}    ${value}
    ${value}    Set Variable If    '${value}' == '_empty_'    ''    ${value}
    RETURN    ${cmd} ${option}=${value}
