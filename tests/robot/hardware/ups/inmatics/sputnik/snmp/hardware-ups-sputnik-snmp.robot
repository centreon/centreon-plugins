*** Settings ***
Documentation       Hardware UPS Sputnik SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=hardware::ups::inmatics::sputnik::snmp::plugin


*** Test Cases ***
Sputnik UPS - Environment ${tc}/9
    [Tags]    hardware    ups    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=environment
    ...    --hostname=127.0.0.1
    ...    --snmp-version=2c
    ...    --snmp-port=2024
    ...    --snmp-community=hardware/ups/inmatics/sputnik/snmp/hardware-ups-sputnik

    # Append options to command
    ${opt}    Append Option    --warning-temperature    ${w_temperature}
    ${command}    Catenate    ${command}    ${opt}
    ${opt}    Append Option    --critical-temperature    ${c_temperature}
    ${command}    Catenate    ${command}    ${opt}
    ${opt}    Append Option    --warning-humidity    ${w_humidity}
    ${command}    Catenate    ${command}    ${opt}
    ${opt}    Append Option    --critical-humidity    ${c_humidity}
    ${command}    Catenate    ${command}    ${opt}
    ${opt}    Append Option    --filter-id    ${filter_id}
    ${command}    Catenate    ${command}    ${opt}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for compliance of ${expected_result}{\n}Command output:{\n}${output}{\n}{\n}{\n}

    Examples:        tc    filter_id    w_temperature    c_temperature    w_humidity    c_humidity    expected_result    --
            ...      1     1            30               50               50            70            OK: 'Sensor 1': temperature 20.06 C, humidity 33 % | 'Sensor 1#environment.temperature.celsius'=20.06C;0:30;0:50;; 'Sensor 1#environment.humidity.percentage'=33%;0:50;0:70;0;100
            ...      2     1            20               50               50            70            WARNING: 'Sensor 1': temperature 20.06 C | 'Sensor 1#environment.temperature.celsius'=20.06C;0:20;0:50;; 'Sensor 1#environment.humidity.percentage'=33%;0:50;0:70;0;100
            ...      3     1            10               20               50            70            CRITICAL: 'Sensor 1': temperature 20.06 C | 'Sensor 1#environment.temperature.celsius'=20.06C;0:10;0:20;; 'Sensor 1#environment.humidity.percentage'=33%;0:50;0:70;0;100
            ...      4     1            30               50               20            70            WARNING: 'Sensor 1': humidity 33 % | 'Sensor 1#environment.temperature.celsius'=20.06C;0:30;0:50;; 'Sensor 1#environment.humidity.percentage'=33%;0:20;0:70;0;100
            ...      5     1            30               50               20            30            CRITICAL: 'Sensor 1': humidity 33 % | 'Sensor 1#environment.temperature.celsius'=20.06C;0:30;0:50;; 'Sensor 1#environment.humidity.percentage'=33%;0:20;0:30;0;100
            ...      6     1            10               50               20            70            WARNING: 'Sensor 1': temperature 20.06 C, humidity 33 % | 'Sensor 1#environment.temperature.celsius'=20.06C;0:10;0:50;; 'Sensor 1#environment.humidity.percentage'=33%;0:20;0:70;0;100
            ...      7     1            10               20               20            30            CRITICAL: 'Sensor 1': temperature 20.06 C, humidity 33 % | 'Sensor 1#environment.temperature.celsius'=20.06C;0:10;0:20;; 'Sensor 1#environment.humidity.percentage'=33%;0:20;0:30;0;100
            ...      8     2            30               50               50            70            UNKNOWN: No sensors found.
            ...      9     1            _empty_          _empty_          _empty_       _empty_       OK: 'Sensor 1': temperature 20.06 C, humidity 33 % | 'Sensor 1#environment.temperature.celsius'=20.06C;;;; 'Sensor 1#environment.humidity.percentage'=33%;;;0;100


*** Keywords ***
Append Option
    [Documentation]    Concatenates the first argument (option) with the second (value) after having replaced the value with "" if its content is '_empty_'
    [Arguments]    ${option}    ${value}
    ${value}    Set Variable If    '${value}' == '_empty_'    ''    ${value}
    RETURN    ${option}=${value}
