*** Settings ***
Documentation       apps::vmware::vsphere8::vcsa::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...         --plugin=apps::vmware::vsphere8::vcsa::plugin
...         --mode=uptime
...         --hostname=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --username=1
...         --password=1


*** Test Cases ***
Uptime ${tc}
    [Tags]    apps    vmware    vcsa
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
    ...    OK: System uptime is: 213d 23h 11m 2s | 'system.uptime.seconds'=18486662.06s;;;0;
    ...    2
    ...    --warning-uptime=1
    ...    WARNING: System uptime is: 213d 23h 11m 2s | 'system.uptime.seconds'=18486662.06s;0:1;;0;
    ...    3
    ...    --critical-uptime=1
    ...    CRITICAL: System uptime is: 213d 23h 11m 2s | 'system.uptime.seconds'=18486662.06s;;0:1;0;
    ...    4
    ...    --warning-uptime=1000 --unit=w
    ...    OK: System uptime is: 213d 23h 11m 2s | 'system.uptime.weeks'=30.57w;0:1000;;0;
    ...    5
    ...    --critical-uptime=1000 --unit=w
    ...    OK: System uptime is: 213d 23h 11m 2s | 'system.uptime.weeks'=30.57w;;0:1000;0;
