*** Settings ***
Documentation       Hardware Camera Avigilon storage

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=hardware::devices::camera::avigilon::snmp::plugin
...         --mode=storage
...         --hostname=127.0.0.1
...         --snmp-port=2024


*** Test Cases ***
Avigilon camera Storage ${tc}/3
    [Documentation]    Hardware Camera Avigilon Storage
    [Tags]    hardware    avigilon    storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/devices/camera/avigilon/snmp/hardware-camera-avigilon
    ...    --warning-status='${warning_status}'
    ...    --critical-status='${critical_status}'
    ...    --unknown-status='${unknown_status}'

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n\n

    Examples:        tc    warning_status                              critical_status                            unknown_status                                expected_result    --
            ...      1     ${EMPTY}                                    ${EMPTY}                                   ${EMPTY}                                      OK: state of the SD card: mediaNotPresent
            ...      2     \\%\{storage_state\} =~ /mediaNotPresent/   ${EMPTY}                                   ${EMPTY}                                      WARNING: state of the SD card: mediaNotPresent
            ...      3     ${EMPTY}                                    \\%\{storage_state\} =~ /mediaNotPresent/  ${EMPTY}                                      CRITICAL: state of the SD card: mediaNotPresent
            ...      4     ${EMPTY}                                    ${EMPTY}                                   \\%\{storage_state\} =~ /mediaNotPresent/     UNKNOWN: state of the SD card: mediaNotPresent
