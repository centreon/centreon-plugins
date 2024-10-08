*** Settings ***
Documentation       Hardware Camera Avigilon temperature

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=hardware::devices::camera::avigilon::snmp::plugin
...         --mode=temperature
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}


*** Test Cases ***
Avigilon camera Temperature ${tc}/5
    [Documentation]    Hardware Camera Avigilon Temperature
    [Tags]    hardware    avigilon    temperature
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/devices/camera/avigilon/snmp/hardware-camera-avigilon
    ...    --warning-temperature='${warning_temperature}'
    ...    --critical-temperature='${critical_temperature}'
    ...    --warning-status='${warning_status}'
    ...    --critical-status='${critical_status}'

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    warning_temperature  critical_temperature    warning_status          critical_status         expected_result    --
            ...      1     ${EMPTY}             ${EMPTY}                ${EMPTY}                ${EMPTY}                OK: temperature: 23.00 C, sensor 1 [type:mainSensor] status: ok | 'sensor.temperature.celsius'=23C;;;0;
            ...      2     20                   ${EMPTY}                ${EMPTY}                ${EMPTY}                WARNING: temperature: 23.00 C | 'sensor.temperature.celsius'=23C;0:20;;0;
            ...      3     ${EMPTY}             20                      ${EMPTY}                ${EMPTY}                CRITICAL: temperature: 23.00 C | 'sensor.temperature.celsius'=23C;;0:20;0;
            ...      4     ${EMPTY}             ${EMPTY}                \\%\{status\} =~ /ok/   ${EMPTY}                WARNING: sensor 1 [type:mainSensor] status: ok | 'sensor.temperature.celsius'=23C;;;0;
            ...      5     ${EMPTY}             ${EMPTY}                ${EMPTY}                \\%\{status\} =~ /ok/   CRITICAL: sensor 1 [type:mainSensor] status: ok | 'sensor.temperature.celsius'=23C;;;0;
