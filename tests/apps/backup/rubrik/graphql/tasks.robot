*** Settings ***
Documentation       apps::backup::rubrik::graphql::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}rubrik-mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::rubrik::graphql::plugin
...                 --mode=tasks
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --service-account=XXX
...                 --secret=XXX


*** Test Cases ***
Tasks ${tc}
    [Tags]    apps    backup    graphql
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Tasks succeeded: 1, failed: 0, canceled: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;;0;
    ...    2
    ...    --start-time=2020-01-01 --end-time=2030-02-02
    ...    OK: Tasks succeeded: 1, failed: 0, canceled: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;;0;
    ...    3
    ...    --last=9999d
    ...    OK: Tasks succeeded: 1, failed: 0, canceled: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;;0;
    ...    4
    ...    --task-category=Protection
    ...    OK: Tasks succeeded: 1, failed: 0, canceled: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;;0;
    ...    5
    ...    --object-type=1
    ...    OK: Tasks succeeded: 1, failed: 0, canceled: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;;0;
    ...    6
    ...    --task-status=1
    ...    OK: Tasks succeeded: 1, failed: 0, canceled: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;;0;
    ...    7
    ...    --task-type=1
    ...    OK: Tasks succeeded: 1, failed: 0, canceled: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;;0;
    ...    8
    ...    --display-on-status=succeeded --verbose
    ...    OK: Tasks succeeded: 1, failed: 0, canceled: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;;0; Task Success: 'Bdc_Service_DB_97e1ec940b6e4498a957965adbd62272' (Mssql, Log Archival), cluster: 'RBKC-IN-DB' (586b76d3-24c4-4fb0-92d3-36a5a39d6e1b), start time: '2026-05-06T10:08:25.000Z', end time '2026-05-06T10:09:33.000Z'
    ...    9
    ...    --warning-succeeded=2:
    ...    WARNING: Tasks succeeded: 1 | 'tasks.succeeded.count'=1;2:;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;;0;
    ...    10
    ...    --critical-succeeded=2:
    ...    CRITICAL: Tasks succeeded: 1 | 'tasks.succeeded.count'=1;;2:;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;;0;
    ...    11
    ...    --warning-failed=1:
    ...    WARNING: Tasks failed: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;1:;;0; 'tasks.canceled.count'=0;;;0;
    ...    12
    ...    --critical-failed=1:
    ...    CRITICAL: Tasks failed: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;1:;0; 'tasks.canceled.count'=0;;;0;
    ...    13
    ...    --warning-canceled=1:
    ...    WARNING: Tasks canceled: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;1:;;0;
    ...    14
    ...    --critical-canceled=1:
    ...    CRITICAL: Tasks canceled: 0 | 'tasks.succeeded.count'=1;;;0; 'tasks.failed.count'=0;;;0; 'tasks.canceled.count'=0;;1:;0;
