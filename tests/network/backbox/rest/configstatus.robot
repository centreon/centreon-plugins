*** Settings ***
Documentation       Check the config status

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
...                 --mode=configstatus


*** Test Cases ***
jobs ${tc}
    [Documentation]    Check the config status
    [Tags]    network    backbox    rest    configstatus
    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                expected_result    --
            ...       1     ${EMPTY}                    OK: identical: 3, changed: 4, n/a: 5 | 'config.identical.count'=3;;;0; 'config.changed.count'=4;;;0; 'config.na.count'=5;;;0;
            ...       2     --warning-identical=2       WARNING: identical: 3 | 'config.identical.count'=3;0:2;;0; 'config.changed.count'=4;;;0; 'config.na.count'=5;;;0;
            ...       3     --critical-identical=2      CRITICAL: identical: 3 | 'config.identical.count'=3;;0:2;0; 'config.changed.count'=4;;;0; 'config.na.count'=5;;;0;
            ...       4     --warning-changed=2         WARNING: changed: 4 | 'config.identical.count'=3;;;0; 'config.changed.count'=4;0:2;;0; 'config.na.count'=5;;;0;
            ...       5     --critical-changed=2        CRITICAL: changed: 4 | 'config.identical.count'=3;;;0; 'config.changed.count'=4;;0:2;0; 'config.na.count'=5;;;0;
            ...       6     --warning-na=2              WARNING: n/a: 5 | 'config.identical.count'=3;;;0; 'config.changed.count'=4;;;0; 'config.na.count'=5;0:2;;0;
            ...       7     --critical-na=2             CRITICAL: n/a: 5 | 'config.identical.count'=3;;;0; 'config.changed.count'=4;;;0; 'config.na.count'=5;;0:2;0;
            ...       8     --filter-type=1             OK: identical: 3, changed: 4, n/a: 5 | 'config.identical.count'=3;;;0; 'config.changed.count'=4;;;0; 'config.na.count'=5;;;0;
