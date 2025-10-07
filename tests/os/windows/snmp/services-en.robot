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
Windows Services EN ${tc}
    [Documentation]    Full ASCII
    [Tags]    os    Windows    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=os/windows/snmp/services-en
    ...    --filter-name='${filter}'
    ...    ${extra_option}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    filter           extra_option            expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}                OK: All services are ok | 'services.total.count'=168;;;0; 'services.active.count'=168;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      2     toto             ${EMPTY}                OK: ${SPACE}| 'services.total.count'=0;;;0; 'services.active.count'=0;;;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      3     toto             --critical-active=1:    CRITICAL: Number of services active: 0 | 'services.total.count'=0;;;0; 'services.active.count'=0;;1:;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      4     ${EMPTY}         --critical-active=1:    OK: All services are ok | 'services.total.count'=168;;;0; 'services.active.count'=168;;1:;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
            ...      5     ${EMPTY}         --critical-active=1:1   CRITICAL: Number of services active: 168 | 'services.total.count'=168;;;0; 'services.active.count'=168;;1:1;0; 'services.continue.pending.count'=0;;;0; 'services.pause.pending.count'=0;;;0; 'services.paused.count'=0;;;0;
