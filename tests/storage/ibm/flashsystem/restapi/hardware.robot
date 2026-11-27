*** Settings ***
Documentation     storage::ibm::flashsystem::restapi::plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}flashsystem.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=storage::ibm::flashsystem::restapi::plugin
...                --mode=hardware
...                --hostname=${HOSTNAME}
...                --proto=http
...                --port=${APIPORT}
...                --api-username=user
...                --api-password=pass
...                --statefile-dir=/tmp


*** Test Cases ***
hardware ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Hardware: 35 component(s) - All hardware components are online - Enclosure: temperature 26 C, power draw 543 W - All enclosure subsystems are fully populated | 'hardware.components.detected.count'=35;;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;;;; 'hardware.power.watt'=543W;;;0;
    ...    2
    ...    --include-type='quorum'
    ...    OK: Hardware: 6 component(s) - All hardware components are online - Enclosure: temperature 26 C, power draw 543 W | 'hardware.components.detected.count'=6;;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;;;; 'hardware.power.watt'=543W;;;0;
    ...    3
    ...    --exclude-name='.*'
    ...    OK: Hardware: 0 component(s) - Enclosure: temperature 26 C, power draw 543 W | 'hardware.components.detected.count'=0;;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;;;; 'hardware.power.watt'=543W;;;0;
    ...    4
    ...    --warning-component-status='\\\%{status} =~ /online/' --include-type='battery'
    ...    WARNING: Battery '1:1' status: online - Battery '1:2' status: online | 'hardware.components.detected.count'=2;;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;;;; 'hardware.power.watt'=543W;;;0;
    ...    5
    ...    --warning-temperature=10 --critical-temperature=20
    ...    CRITICAL: Enclosure: temperature 26 C | 'hardware.components.detected.count'=35;;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;0:10;0:20;; 'hardware.power.watt'=543W;;;0;
    ...    6
    ...    --warning-components-detected=10
    ...    WARNING: Hardware: 35 component(s) | 'hardware.components.detected.count'=35;0:10;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;;;; 'hardware.power.watt'=543W;;;0;
