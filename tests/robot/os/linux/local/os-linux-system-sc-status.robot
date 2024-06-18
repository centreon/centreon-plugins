*** Settings ***
Documentation       Linux Local Systemd-sc-status

# systemd changed the output format of the command starting from version 252, so we need to check for a systemd version and use the correct parameter.
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::local::plugin


*** Test Cases ***
Systemd-sc-status v219 ${tc}/15
    [Documentation]    Systemd version < 248
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=systemd-sc-status
    ...    --command-path=${CURDIR}${/}systemd-219
    ...    --filter-name='${filter}'
    ...    --exclude-name='${exclude}'
    ...    --warning-status='${w_stat}'
    ...    --critical-status='${c_stat}'
    ...    --warning-total-running='${w_running}'
    ...    --critical-total-running='${c_running}'
    ...    --warning-total-dead='${w_dead}'
    ...    --critical-total-dead='${c_dead}'
    ...    --warning-total-exited='${w_exited}'
    ...    --critical-total-exited='${c_exited}'
    ...    --warning-total-failed='${w_failed}'
    ...    --critical-total-failed='${c_failed}'

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:        tc    filter          exclude    w_stat    c_stat    w_running    c_running    w_dead    c_dead    w_exited    c_exited    w_failed    c_failed    expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     OK: Total Running: 34, Total Failed: 1, Total Dead: 97, Total Exited: 25 - All services are ok | 'total_running'=34;;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;;0;220
            ...      2     toto            ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     UNKNOWN: No service found.
            ...      3     NetworkManager  ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     OK: Total Running: 1, Total Failed: 0, Total Dead: 0, Total Exited: 1 - All services are ok | 'total_running'=1;;;0;2 'total_failed'=0;;;0;2 'total_dead'=0;;;0;2 'total_exited'=1;;;0;2
            ...      4     ${EMPTY}         Manager    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     OK: Total Running: 33, Total Failed: 1, Total Dead: 97, Total Exited: 24 - All services are ok | 'total_running'=33;;;0;218 'total_failed'=1;;;0;218 'total_dead'=97;;;0;218 'total_exited'=24;;;0;218
            ...      5     NetworkManager  ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     OK: Total Running: 1, Total Failed: 0, Total Dead: 0, Total Exited: 1 - All services are ok | 'total_running'=1;;;0;2 'total_failed'=0;;;0;2 'total_dead'=0;;;0;2 'total_exited'=1;;;0;2
            ...      8     ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  0             ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     WARNING: Total Running: 34 | 'total_running'=34;0:0;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;;0;220
            ...      9     ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       0            ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     CRITICAL: Total Running: 34 | 'total_running'=34;;0:0;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;;0;220
            ...      10    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      0         ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     WARNING: Total Dead: 97 | 'total_running'=34;;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;0:0;;0;220 'total_exited'=25;;;0;220
            ...      11    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   0        ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     CRITICAL: Total Dead: 97 | 'total_running'=34;;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;0:0;0;220 'total_exited'=25;;;0;220
            ...      12    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  0            ${EMPTY}     ${EMPTY}     ${EMPTY}     WARNING: Total Exited: 25 | 'total_running'=34;;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;0:0;;0;220
            ...      13    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      0           ${EMPTY}     ${EMPTY}     CRITICAL: Total Exited: 25 | 'total_running'=34;;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;0:0;0;220
            ...      14    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     0           ${EMPTY}     WARNING: Total Failed: 1 | 'total_running'=34;;;0;220 'total_failed'=1;0:0;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;;0;220
            ...      15    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     0           CRITICAL: Total Failed: 1 | 'total_running'=34;;;0;220 'total_failed'=1;;0:0;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;;0;220

Systemd-sc-status v252 ${tc}/15
    [Documentation]    Systemd version >= 248
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=systemd-sc-status
    ...    --command-path=${CURDIR}${/}systemd-252
    ...    --filter-name='${filter}'
    ...    --exclude-name='${exclude}'
    ...    --warning-status='${w_stat}'
    ...    --critical-status='${c_stat}'
    ...    --warning-total-running='${w_running}'
    ...    --critical-total-running='${c_running}'
    ...    --warning-total-dead='${w_dead}'
    ...    --critical-total-dead='${c_dead}'
    ...    --warning-total-exited='${w_exited}'
    ...    --critical-total-exited='${c_exited}'
    ...    --warning-total-failed='${w_failed}'
    ...    --critical-total-failed='${c_failed}'

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n\n

    Examples:        tc    filter          exclude    w_stat    c_stat    w_running    c_running    w_dead    c_dead    w_exited    c_exited    w_failed    c_failed    expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     OK: Total Running: 31, Total Failed: 4, Total Dead: 108, Total Exited: 19 - All services are ok | 'total_running'=31;;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;;0;258
            ...      2     toto            ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     UNKNOWN: No service found.
            ...      3     NetworkManager  ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     OK: Total Running: 1, Total Failed: 0, Total Dead: 0, Total Exited: 1 - All services are ok | 'total_running'=1;;;0;2 'total_failed'=0;;;0;2 'total_dead'=0;;;0;2 'total_exited'=1;;;0;2
            ...      4     ${EMPTY}         Manager    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     OK: Total Running: 30, Total Failed: 4, Total Dead: 108, Total Exited: 18 - All services are ok | 'total_running'=30;;;0;256 'total_failed'=4;;;0;256 'total_dead'=108;;;0;256 'total_exited'=18;;;0;256
            ...      5     NetworkManager  ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     OK: Total Running: 1, Total Failed: 0, Total Dead: 0, Total Exited: 1 - All services are ok | 'total_running'=1;;;0;2 'total_failed'=0;;;0;2 'total_dead'=0;;;0;2 'total_exited'=1;;;0;2
            ...      8     ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  2             ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     WARNING: Total Running: 31 | 'total_running'=31;0:2;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;;0;258
            ...      9     ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       2            ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     CRITICAL: Total Running: 31 | 'total_running'=31;;0:2;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;;0;258
            ...      10    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      2         ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     WARNING: Total Dead: 108 | 'total_running'=31;;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;0:2;;0;258 'total_exited'=19;;;0;258
            ...      11    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   2        ${EMPTY}      ${EMPTY}     ${EMPTY}     ${EMPTY}     CRITICAL: Total Dead: 108 | 'total_running'=31;;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;0:2;0;258 'total_exited'=19;;;0;258
            ...      12    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  2            ${EMPTY}     ${EMPTY}     ${EMPTY}     WARNING: Total Exited: 19 | 'total_running'=31;;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;0:2;;0;258
            ...      13    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      2           ${EMPTY}     ${EMPTY}     CRITICAL: Total Exited: 19 | 'total_running'=31;;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;0:2;0;258
            ...      14    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     2           ${EMPTY}     WARNING: Total Failed: 4 | 'total_running'=31;;;0;258 'total_failed'=4;0:2;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;;0;258
            ...      15    ${EMPTY}         ${EMPTY}    ${EMPTY}   ${EMPTY}  ${EMPTY}       ${EMPTY}      ${EMPTY}   ${EMPTY}  ${EMPTY}      ${EMPTY}     ${EMPTY}     2           CRITICAL: Total Failed: 4 | 'total_running'=31;;;0;258 'total_failed'=4;;0:2;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;;0;258
