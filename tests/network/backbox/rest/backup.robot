*** Settings ***
Documentation       Check the backup status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}backbox.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=network::backbox::rest::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token=token


*** Test Cases ***
jobs ${tc}
    [Documentation]    Check the backups status
    [Tags]    network    backbox    rest    backup
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=backup
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                expected_result    --
            ...       1     ${EMPTY}                    OK: All backups are ok | 'All#backups.total.count'=5;;;0; 'All#backups.success.count'=0;;;0; 'All#backups.suspect.count'=1;;;0; 'All#backups.failure.count'=4;;;0; 'Backup1#backups.total.count'=6;;;0; 'Backup1#backups.success.count'=1;;;0; 'Backup1#backups.suspect.count'=2;;;0; 'Backup1#backups.failure.count'=3;;;0;
            ...       2     --warning-failure=3         WARNING: Backup 'All' - failure: 4 | 'All#backups.total.count'=5;;;0; 'All#backups.success.count'=0;;;0; 'All#backups.suspect.count'=1;;;0; 'All#backups.failure.count'=4;0:3;;0; 'Backup1#backups.total.count'=6;;;0; 'Backup1#backups.success.count'=1;;;0; 'Backup1#backups.suspect.count'=2;;;0; 'Backup1#backups.failure.count'=3;0:3;;0;
            ...       3     --critical-failure=3        CRITICAL: Backup 'All' - failure: 4 | 'All#backups.total.count'=5;;;0; 'All#backups.success.count'=0;;;0; 'All#backups.suspect.count'=1;;;0; 'All#backups.failure.count'=4;;0:3;0; 'Backup1#backups.total.count'=6;;;0; 'Backup1#backups.success.count'=1;;;0; 'Backup1#backups.suspect.count'=2;;;0; 'Backup1#backups.failure.count'=3;;0:3;0;
            ...       4     --warning-failure=2         WARNING: Backup 'All' - failure: 4 - Backup 'Backup1' - failure: 3 | 'All#backups.total.count'=5;;;0; 'All#backups.success.count'=0;;;0; 'All#backups.suspect.count'=1;;;0; 'All#backups.failure.count'=4;0:2;;0; 'Backup1#backups.total.count'=6;;;0; 'Backup1#backups.success.count'=1;;;0; 'Backup1#backups.suspect.count'=2;;;0; 'Backup1#backups.failure.count'=3;0:2;;0;
            ...       5     --critical-failure=2        CRITICAL: Backup 'All' - failure: 4 - Backup 'Backup1' - failure: 3 | 'All#backups.total.count'=5;;;0; 'All#backups.success.count'=0;;;0; 'All#backups.suspect.count'=1;;;0; 'All#backups.failure.count'=4;;0:2;0; 'Backup1#backups.total.count'=6;;;0; 'Backup1#backups.success.count'=1;;;0; 'Backup1#backups.suspect.count'=2;;;0; 'Backup1#backups.failure.count'=3;;0:2;0;
            ...       6     --warning-suspect=1         WARNING: Backup 'Backup1' - suspect: 2 | 'All#backups.total.count'=5;;;0; 'All#backups.success.count'=0;;;0; 'All#backups.suspect.count'=1;0:1;;0; 'All#backups.failure.count'=4;;;0; 'Backup1#backups.total.count'=6;;;0; 'Backup1#backups.success.count'=1;;;0; 'Backup1#backups.suspect.count'=2;0:1;;0; 'Backup1#backups.failure.count'=3;;;0;
            ...       7     --critical-suspect=1        CRITICAL: Backup 'Backup1' - suspect: 2 | 'All#backups.total.count'=5;;;0; 'All#backups.success.count'=0;;;0; 'All#backups.suspect.count'=1;;0:1;0; 'All#backups.failure.count'=4;;;0; 'Backup1#backups.total.count'=6;;;0; 'Backup1#backups.success.count'=1;;;0; 'Backup1#backups.suspect.count'=2;;0:1;0; 'Backup1#backups.failure.count'=3;;;0;
            ...       8     --filter-type=1             OK: All backups are ok | 'All#backups.total.count'=5;;;0; 'All#backups.success.count'=0;;;0; 'All#backups.suspect.count'=1;;;0; 'All#backups.failure.count'=4;;;0; 'Backup1#backups.total.count'=6;;;0; 'Backup1#backups.success.count'=1;;;0; 'Backup1#backups.suspect.count'=2;;;0; 'Backup1#backups.failure.count'=3;;;0;
