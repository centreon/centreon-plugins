*** Settings ***
Documentation       Check the intellichecks status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}backbox.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=network::backbox::restapi::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token=token
...                 --mode=intellicheck


*** Test Cases ***
intellichecks ${tc}
    [Documentation]    Check the intellichecks status
    [Tags]    network    backbox    restapi    intellicheck
    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                        expected_result    --
            ...       1     ${EMPTY}                            OK: All intellichecks are ok | 'All#intellicheck.total.count'=12;;;0; 'All#intellicheck.success.count'=3;;;0;12 'All#intellicheck.suspect.count'=4;;;0;12 'All#intellicheck.failure.count'=5;;;0;12 'IntelliCheck1#intellicheck.total.count'=12;;;0; 'IntelliCheck1#intellicheck.success.count'=5;;;0;12 'IntelliCheck1#intellicheck.suspect.count'=4;;;0;12 'IntelliCheck1#intellicheck.failure.count'=3;;;0;12
            ...       2     --warning-failure=3                 WARNING: Intellicheck 0 'All' - failure: 5 | 'All#intellicheck.total.count'=12;;;0; 'All#intellicheck.success.count'=3;;;0;12 'All#intellicheck.suspect.count'=4;;;0;12 'All#intellicheck.failure.count'=5;0:3;;0;12 'IntelliCheck1#intellicheck.total.count'=12;;;0; 'IntelliCheck1#intellicheck.success.count'=5;;;0;12 'IntelliCheck1#intellicheck.suspect.count'=4;;;0;12 'IntelliCheck1#intellicheck.failure.count'=3;0:3;;0;12
            ...       3     --critical-failure=3                CRITICAL: Intellicheck 0 'All' - failure: 5 | 'All#intellicheck.total.count'=12;;;0; 'All#intellicheck.success.count'=3;;;0;12 'All#intellicheck.suspect.count'=4;;;0;12 'All#intellicheck.failure.count'=5;;0:3;0;12 'IntelliCheck1#intellicheck.total.count'=12;;;0; 'IntelliCheck1#intellicheck.success.count'=5;;;0;12 'IntelliCheck1#intellicheck.suspect.count'=4;;;0;12 'IntelliCheck1#intellicheck.failure.count'=3;;0:3;0;12
            ...       4     --warning-failure=2                 WARNING: Intellicheck 0 'All' - failure: 5 - Intellicheck 0 'IntelliCheck1' - failure: 3 | 'All#intellicheck.total.count'=12;;;0; 'All#intellicheck.success.count'=3;;;0;12 'All#intellicheck.suspect.count'=4;;;0;12 'All#intellicheck.failure.count'=5;0:2;;0;12 'IntelliCheck1#intellicheck.total.count'=12;;;0; 'IntelliCheck1#intellicheck.success.count'=5;;;0;12 'IntelliCheck1#intellicheck.suspect.count'=4;;;0;12 'IntelliCheck1#intellicheck.failure.count'=3;0:2;;0;12
            ...       5     --critical-failure=2                CRITICAL: Intellicheck 0 'All' - failure: 5 - Intellicheck 0 'IntelliCheck1' - failure: 3 | 'All#intellicheck.total.count'=12;;;0; 'All#intellicheck.success.count'=3;;;0;12 'All#intellicheck.suspect.count'=4;;;0;12 'All#intellicheck.failure.count'=5;;0:2;0;12 'IntelliCheck1#intellicheck.total.count'=12;;;0; 'IntelliCheck1#intellicheck.success.count'=5;;;0;12 'IntelliCheck1#intellicheck.suspect.count'=4;;;0;12 'IntelliCheck1#intellicheck.failure.count'=3;;0:2;0;12
            ...       6     --warning-suspect=1                 WARNING: Intellicheck 0 'All' - suspect: 4 - Intellicheck 0 'IntelliCheck1' - suspect: 4 | 'All#intellicheck.total.count'=12;;;0; 'All#intellicheck.success.count'=3;;;0;12 'All#intellicheck.suspect.count'=4;0:1;;0;12 'All#intellicheck.failure.count'=5;;;0;12 'IntelliCheck1#intellicheck.total.count'=12;;;0; 'IntelliCheck1#intellicheck.success.count'=5;;;0;12 'IntelliCheck1#intellicheck.suspect.count'=4;0:1;;0;12 'IntelliCheck1#intellicheck.failure.count'=3;;;0;12
            ...       7     --critical-suspect=1                CRITICAL: Intellicheck 0 'All' - suspect: 4 - Intellicheck 0 'IntelliCheck1' - suspect: 4 | 'All#intellicheck.total.count'=12;;;0; 'All#intellicheck.success.count'=3;;;0;12 'All#intellicheck.suspect.count'=4;;0:1;0;12 'All#intellicheck.failure.count'=5;;;0;12 'IntelliCheck1#intellicheck.total.count'=12;;;0; 'IntelliCheck1#intellicheck.success.count'=5;;;0;12 'IntelliCheck1#intellicheck.suspect.count'=4;;0:1;0;12 'IntelliCheck1#intellicheck.failure.count'=3;;;0;12
            ...       8     --filter-type=1                     OK: All intellichecks are ok | 'All#intellicheck.total.count'=12;;;0; 'All#intellicheck.success.count'=3;;;0;12 'All#intellicheck.suspect.count'=4;;;0;12 'All#intellicheck.failure.count'=5;;;0;12 'IntelliCheck1#intellicheck.total.count'=12;;;0; 'IntelliCheck1#intellicheck.success.count'=5;;;0;12 'IntelliCheck1#intellicheck.suspect.count'=4;;;0;12 'IntelliCheck1#intellicheck.failure.count'=3;;;0;12
            ...       9     --report-id=1                       UNKNOWN: Need to specify --filter-type option.
            ...       10    --filter-type=1 --report-id=1       OK: All intellichecks are ok | 'All#intellicheck.total.count'=12;;;0; 'All#intellicheck.success.count'=3;;;0;12 'All#intellicheck.suspect.count'=4;;;0;12 'All#intellicheck.failure.count'=5;;;0;12 'IntelliCheck1#intellicheck.total.count'=12;;;0; 'IntelliCheck1#intellicheck.success.count'=5;;;0;12 'IntelliCheck1#intellicheck.suspect.count'=4;;;0;12 'IntelliCheck1#intellicheck.failure.count'=3;;;0;12
