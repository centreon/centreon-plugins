*** Settings ***
Documentation       Check local Windows operating system.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}


*** Test Cases ***
cpu ${tc}
    [Tags]    os    windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::local::plugin
    ...    --mode=sessions
    ...    --command=${qwinsta_command}
    ...    --command-path=${CURDIR}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    qwinsta_command     expected_result    --
            ...      1     qwinsta1    OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 0, current disconnected : 0 | 'sessions_active'=0;;;0; 'sessions_disconnected_current'=0;;;0;
            ...      2     qwinsta2    OK: 2 CPU(s) average usage is 0.50 % | 'total_cpu_avg'=0.50%;0:80;0:90;0;100 'cpu_0'=1.00%;;;0;100 'cpu_1'=0.00%;;;0;100
