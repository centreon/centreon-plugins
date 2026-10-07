*** Settings ***
Documentation       Check local Windows operating system.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}


*** Test Cases ***
session ${tc}
    [Tags]    os    windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::local::plugin
    ...    --mode=sessions
    ...    --command=${qwinsta_command}
    ...    --command-path=${CURDIR}
    ...    --command-options="/COUNTER ${lang}"

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    qwinsta_command    lang    expected_result    --
            ...      1     qwinsta1           en      OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 0, current disconnected : 0 | 'sessions_active'=0;;;0; 'sessions_disconnected_current'=0;;;0;
            ...      2     qwinsta2           en      OK: Sessions created: 7, disconnected: 2, reconnected : 2, current active : 0, current disconnected : 0 | 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=0;;;0; 'sessions_disconnected_current'=0;;;0;
            ...      3     qwinsta1           de      OK: Sessions sessions-created : Buffer creation, sessions-disconnected : Buffer creation, sessions-reconnected : Buffer creation, current active : 0, current disconnected : 0 | 'sessions_active'=0;;;0; 'sessions_disconnected_current'=0;;;0;
            ...      4     qwinsta2           de      OK: Sessions created: 7, disconnected: 2, reconnected : 2, current active : 0, current disconnected : 0 | 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=0;;;0; 'sessions_disconnected_current'=0;;;0;

sessions line endings and encoding ${tc}
    [Tags]    os    windows
    # qwinsta3: CRLF line endings, qwinsta4: CRLF line endings and CP850 encoding (as on Windows)
    # First run stores the counters read from the tested output, second run (LF, UTF-8) checks the delta
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::local::plugin
    ...    --mode=sessions
    ...    --command-path=${CURDIR}
    ...    --command-options="/COUNTER ${lang}"
    ...    --language=${lang}
    ...    --statefile-suffix=line-endings-encoding-${tc}

    Run    ${command} --command=${qwinsta_command}
    Ctn Run Command And Check Result As Regexp    ${command} --command=qwinsta2    ${expected_result}

    Examples:        tc    qwinsta_command    lang    expected_result    --
            ...      1     qwinsta1           en      OK: Sessions created: 7, disconnected: 2, reconnected : 2, current active : 0, current disconnected : 0 [|] 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=0;;;0; 'sessions_disconnected_current'=0;;;0;
            ...      2     qwinsta3           en      OK: Sessions created: 7, disconnected: 2, reconnected : 2, current active : 0, current disconnected : 0 [|] 'sessions_created'=7;;;0; 'sessions_disconnected'=2;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=0;;;0; 'sessions_disconnected_current'=0;;;0;
            ...      3     qwinsta1           de      OK: Sessions created: 11, disconnected: 5, reconnected : 2, current active : 2, current disconnected : 1 [|] 'sessions_created'=11;;;0; 'sessions_disconnected'=5;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0;
            ...      4     qwinsta3           de      OK: Sessions created: 11, disconnected: 5, reconnected : 2, current active : 2, current disconnected : 1 [|] 'sessions_created'=11;;;0; 'sessions_disconnected'=5;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0;
            ...      5     qwinsta4           de      OK: Sessions created: 11, disconnected: 5, reconnected : 2, current active : 2, current disconnected : 1 [|] 'sessions_created'=11;;;0; 'sessions_disconnected'=5;;;0; 'sessions_reconnected'=2;;;0; 'sessions_active'=2;;;0; 'sessions_disconnected_current'=1;;;0;
