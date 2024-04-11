*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=os::windows::snmp::plugin
...         --mode=service
...         --hostname=127.0.0.1
...         --snmp-port=2024


*** Test Cases ***
Windows Services EN ${tc}/x
    [Documentation]    Full ASCII
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=os/windows/snmp/services-en
    ...    --filter-name='${filter}'
    ...    ${extra_option}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n\n

    Examples:        tc    filter           extra_option            expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}                OK: All services are ok | 'services.total.count'=168;;;0; 'services.active.count'=168;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      2     toto             ${EMPTY}                OK: ${SPACE}| 'services.total.count'=0;;;0; 'services.active.count'=0;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      3     toto             --critical-active=1:    CRITICAL: Number of services active: 0 | 'services.total.count'=0;;;0; 'services.active.count'=0;;1:;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      4     ${EMPTY}         --critical-active=1:    OK: All services are ok | 'services.total.count'=168;;;0; 'services.active.count'=168;;1:;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      5     ${EMPTY}         --critical-active=1:1   CRITICAL: Number of services active: 168 | 'services.total.count'=168;;;0; 'services.active.count'=168;;1:1;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;

Windows Services FR ${tc}/x
    [Documentation]    Systemd version < 248
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=os/windows/snmp/services-fr
    ...    --filter-name='${filter}'
    ...    ${extra_option}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n\n

    Examples:        tc    filter           extra_option            expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}                    OK: All services are ok | 'services.total.count'=80;;;0; 'services.active.count'=80;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      2     toto             ${EMPTY}                    OK: ${SPACE}| 'services.total.count'=0;;;0; 'services.active.count'=0;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      3     toto             --critical-active=1:        CRITICAL: Number of services active: 0 | 'services.total.count'=0;;;0; 'services.active.count'=0;;1:;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      4     ${EMPTY}         --critical-active=1:        OK: All services are ok | 'services.total.count'=80;;;0; 'services.active.count'=80;;1:;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      5     ${EMPTY}         --critical-active=1:1       CRITICAL: Number of services active: 80 | 'services.total.count'=80;;;0; 'services.active.count'=80;;1:1;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      6     .v.nement        --critical-active=1:        OK: All services are ok | 'services.total.count'=5;;;0; 'services.active.count'=5;;1:;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      7     \xe9v\xe9nement  ${EMPTY}                    OK: All services are ok | 'services.total.count'=5;;;0; 'services.active.count'=5;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      8     SNMP             ${EMPTY}                    OK: Service 'Service SNMP' state is 'active' [installed state: 'installed'] | 'services.total.count'=1;;;0; 'services.active.count'=1;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
