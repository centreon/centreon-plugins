*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=os::windows::snmp::plugin
...         --mode=service
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}


*** Test Cases ***
Windows Services FR ${tc}
    [Documentation]    Systemd version < 248
    [Tags]    os    Windows    local
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

    Examples:        tc    filter           extra_option                expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}                    OK: All services are ok | 'services.total.count'=80;;;0; 'services.active.count'=80;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      2     toto             ${EMPTY}                    OK: ${SPACE}| 'services.total.count'=0;;;0; 'services.active.count'=0;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      3     toto             --critical-active=1:        CRITICAL: Number of services active: 0 | 'services.total.count'=0;;;0; 'services.active.count'=0;;1:;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      4     ${EMPTY}         --critical-active=1:        OK: All services are ok | 'services.total.count'=80;;;0; 'services.active.count'=80;;1:;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      5     ${EMPTY}         --critical-active=1:1       CRITICAL: Number of services active: 80 | 'services.total.count'=80;;;0; 'services.active.count'=80;;1:1;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      6     .v.nement        --critical-active=1:        OK: All services are ok | 'services.total.count'=5;;;0; 'services.active.count'=5;;1:;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      7     \xe9v\xe9nement  ${EMPTY}                    OK: All services are ok | 'services.total.count'=5;;;0; 'services.active.count'=5;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      8     SNMP             ${EMPTY}                    OK: Service 'Service SNMP' state is 'active' [installed state: 'installed'] | 'services.total.count'=1;;;0; 'services.active.count'=1;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
