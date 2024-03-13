*** Settings ***
Documentation       OS Linux Local plugin Systemd-sc-status

Library             OperatingSystem
Library             String
Library             Examples

Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}         ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                      perl ${CENTREON_PLUGINS} --plugin=os::linux::local::plugin
${PERCENT}                  %

${COND}                     ${PERCENT}\{sub\} =~ /exited/ && ${PERCENT}{display} =~ /network/'

*** Test Cases ***
Systemd-sc-status v219 ${tc}/15
    [Documentation]    Systemd version < 248
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=systemd-sc-status
    ...    --command-path=${CURDIR}${/}..${/}..${/}resources${/}linux${/}systemd-219

    # Test simple usage of the systemd-sc-status mode

    # Append options to command
    ${command}     Append Option To Command    ${command}     --filter-name             ${filter}
    ${command}     Append Option To Command    ${command}     --exclude-name            ${exclude}
    ${command}     Append Option To Command    ${command}     --warning-status          ${w_stat}
    ${command}     Append Option To Command    ${command}     --critical-status         ${c_stat}
    ${command}     Append Option To Command    ${command}     --warning-total-running   ${w_running}
    ${command}     Append Option To Command    ${command}     --critical-total-running  ${c_running}
    ${command}     Append Option To Command    ${command}     --warning-total-dead      ${w_dead}
    ${command}     Append Option To Command    ${command}     --critical-total-dead     ${c_dead}
    ${command}     Append Option To Command    ${command}     --warning-total-exited    ${w_exited}
    ${command}     Append Option To Command    ${command}     --critical-total-exited   ${c_exited}
    ${command}     Append Option To Command    ${command}     --warning-total-failed    ${w_failed}
    ${command}     Append Option To Command    ${command}     --critical-total-failed   ${c_failed}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:        tc    filter          exclude    w_stat    c_stat    w_running    c_running    w_dead    c_dead    w_exited    c_exited    w_failed    c_failed    expected_result    --
            ...      1     _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     OK: Total Running: 34, Total Failed: 1, Total Dead: 97, Total Exited: 25 - All services are ok | 'total_running'=34;;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;;0;220
            ...      2     toto            _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     UNKNOWN: No service found.
            ...      3     NetworkManager  _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     OK: Total Running: 1, Total Failed: 0, Total Dead: 0, Total Exited: 1 - All services are ok | 'total_running'=1;;;0;2 'total_failed'=0;;;0;2 'total_dead'=0;;;0;2 'total_exited'=1;;;0;2
            ...      4     _empty_         Manager    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     OK: Total Running: 33, Total Failed: 1, Total Dead: 97, Total Exited: 24 - All services are ok | 'total_running'=33;;;0;218 'total_failed'=1;;;0;218 'total_dead'=97;;;0;218 'total_exited'=24;;;0;218
            ...      5     NetworkManager  _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     OK: Total Running: 1, Total Failed: 0, Total Dead: 0, Total Exited: 1 - All services are ok | 'total_running'=1;;;0;2 'total_failed'=0;;;0;2 'total_dead'=0;;;0;2 'total_exited'=1;;;0;2
            ...      8     _empty_         _empty_    _empty_   _empty_  0             _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     WARNING: Total Running: 34 | 'total_running'=34;0:0;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;;0;220
            ...      9     _empty_         _empty_    _empty_   _empty_  _empty_       0            _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     CRITICAL: Total Running: 34 | 'total_running'=34;;0:0;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;;0;220
            ...      10    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      0         _empty_  _empty_      _empty_     _empty_     _empty_     WARNING: Total Dead: 97 | 'total_running'=34;;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;0:0;;0;220 'total_exited'=25;;;0;220
            ...      11    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   0        _empty_      _empty_     _empty_     _empty_     CRITICAL: Total Dead: 97 | 'total_running'=34;;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;0:0;0;220 'total_exited'=25;;;0;220
            ...      12    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  0            _empty_     _empty_     _empty_     WARNING: Total Exited: 25 | 'total_running'=34;;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;0:0;;0;220
            ...      13    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      0           _empty_     _empty_     CRITICAL: Total Exited: 25 | 'total_running'=34;;;0;220 'total_failed'=1;;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;0:0;0;220
            ...      14    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     0           _empty_     WARNING: Total Failed: 1 | 'total_running'=34;;;0;220 'total_failed'=1;0:0;;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;;0;220
            ...      15    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     0           CRITICAL: Total Failed: 1 | 'total_running'=34;;;0;220 'total_failed'=1;;0:0;0;220 'total_dead'=97;;;0;220 'total_exited'=25;;;0;220
# not working atm
            # ...      6     _empty_         _empty_    ${COND}   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     WARNING
            # ...      7     _empty_         _empty_    _empty_   ${COND}  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     CRITICAL

Systemd-sc-status v252 ${tc}/15
    [Documentation]    Systemd version >= 248
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=systemd-sc-status
    ...    --command-path=${CURDIR}${/}..${/}..${/}resources${/}linux${/}systemd-252

    # Test simple usage of the systemd-sc-status mode

    # Append options to command
    ${command}     Append Option To Command    ${command}     --filter-name             ${filter}
    ${command}     Append Option To Command    ${command}     --exclude-name            ${exclude}
    ${command}     Append Option To Command    ${command}     --warning-status          ${w_stat}
    ${command}     Append Option To Command    ${command}     --critical-status         ${c_stat}
    ${command}     Append Option To Command    ${command}     --warning-total-running   ${w_running}
    ${command}     Append Option To Command    ${command}     --critical-total-running  ${c_running}
    ${command}     Append Option To Command    ${command}     --warning-total-dead      ${w_dead}
    ${command}     Append Option To Command    ${command}     --critical-total-dead     ${c_dead}
    ${command}     Append Option To Command    ${command}     --warning-total-exited    ${w_exited}
    ${command}     Append Option To Command    ${command}     --critical-total-exited   ${c_exited}
    ${command}     Append Option To Command    ${command}     --warning-total-failed    ${w_failed}
    ${command}     Append Option To Command    ${command}     --critical-total-failed   ${c_failed}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n\n

    Examples:        tc    filter          exclude    w_stat    c_stat    w_running    c_running    w_dead    c_dead    w_exited    c_exited    w_failed    c_failed    expected_result    --
            ...      1     _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     OK: Total Running: 31, Total Failed: 4, Total Dead: 108, Total Exited: 19 - All services are ok | 'total_running'=31;;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;;0;258
            ...      2     toto            _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     UNKNOWN: No service found.
            ...      3     NetworkManager  _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     OK: Total Running: 1, Total Failed: 0, Total Dead: 0, Total Exited: 1 - All services are ok | 'total_running'=1;;;0;2 'total_failed'=0;;;0;2 'total_dead'=0;;;0;2 'total_exited'=1;;;0;2
            ...      4     _empty_         Manager    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     OK: Total Running: 30, Total Failed: 4, Total Dead: 108, Total Exited: 18 - All services are ok | 'total_running'=30;;;0;256 'total_failed'=4;;;0;256 'total_dead'=108;;;0;256 'total_exited'=18;;;0;256
            ...      5     NetworkManager  _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     OK: Total Running: 1, Total Failed: 0, Total Dead: 0, Total Exited: 1 - All services are ok | 'total_running'=1;;;0;2 'total_failed'=0;;;0;2 'total_dead'=0;;;0;2 'total_exited'=1;;;0;2
            ...      8     _empty_         _empty_    _empty_   _empty_  2             _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     WARNING: Total Running: 31 | 'total_running'=31;0:2;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;;0;258
            ...      9     _empty_         _empty_    _empty_   _empty_  _empty_       2            _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     CRITICAL: Total Running: 31 | 'total_running'=31;;0:2;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;;0;258
            ...      10    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      2         _empty_  _empty_      _empty_     _empty_     _empty_     WARNING: Total Dead: 108 | 'total_running'=31;;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;0:2;;0;258 'total_exited'=19;;;0;258
            ...      11    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   2        _empty_      _empty_     _empty_     _empty_     CRITICAL: Total Dead: 108 | 'total_running'=31;;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;0:2;0;258 'total_exited'=19;;;0;258
            ...      12    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  2            _empty_     _empty_     _empty_     WARNING: Total Exited: 19 | 'total_running'=31;;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;0:2;;0;258
            ...      13    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      2           _empty_     _empty_     CRITICAL: Total Exited: 19 | 'total_running'=31;;;0;258 'total_failed'=4;;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;0:2;0;258
            ...      14    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     2           _empty_     WARNING: Total Failed: 4 | 'total_running'=31;;;0;258 'total_failed'=4;0:2;;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;;0;258
            ...      15    _empty_         _empty_    _empty_   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     2           CRITICAL: Total Failed: 4 | 'total_running'=31;;;0;258 'total_failed'=4;;0:2;0;258 'total_dead'=108;;;0;258 'total_exited'=19;;;0;258

# not working atm
            # ...      6     _empty_         _empty_    ${COND}   _empty_  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     WARNING
            # ...      7     _empty_         _empty_    _empty_   ${COND}  _empty_       _empty_      _empty_   _empty_  _empty_      _empty_     _empty_     _empty_     CRITICAL

*** Keywords ***
Append Option To Command
    [Documentation]    Concatenates the first argument (option) with the second (value) after having replaced the value with "" if its content is '_empty_'
    [Arguments]    ${command}    ${option}    ${value}
    ${value}    Set Variable If    '${value}' == '_empty_'    ''    '${value}'
    [return]    ${command} ${option}=${value}

