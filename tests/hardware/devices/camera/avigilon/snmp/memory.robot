*** Settings ***
Documentation       Hardware Camera Avigilon memory

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=hardware::devices::camera::avigilon::snmp::plugin
...         --mode=memory
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}


*** Test Cases ***
Avigilon camera Memory ${tc}/3
    [Documentation]    Hardware Camera Avigilon Memory
    [Tags]    hardware    avigilon    memory
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/devices/camera/avigilon/snmp/hardware-camera-avigilon
    ...    --warning-available='${warning_available}'
    ...    --critical-available='${critical_available}'

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    warning_available    critical_available      expected_result    --
            ...      1     ${EMPTY}             ${EMPTY}                OK: total system memory available: 464.85 KB | 'memory.available'=476004B;;;0;
            ...      2     5000                 ${EMPTY}                WARNING: total system memory available: 464.85 KB | 'memory.available'=476004B;0:5000;;0;
            ...      3     ${EMPTY}             5000                    CRITICAL: total system memory available: 464.85 KB | 'memory.available'=476004B;;0:5000;0;
