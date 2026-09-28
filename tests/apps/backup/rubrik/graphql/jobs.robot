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
...                 --mode=jobs
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --service-account=XXX
...                 --secret=XXX


*** Test Cases ***
Jobs ${tc}
    [Tags]    apps    backup    graphql
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All jobs are ok
    ...    2
    ...    --start-time=2020-01-01 --end-time=2030-02-02
    ...    OK: All jobs are ok
    ...    3
    ...    --exclude-cluster=abcdeff-xwxwxwxw-xwxwxw-xwxwxw-xwxwxw
    ...    OK: All jobs are ok
    ...    4
    ...    --updated-start-time=2020-01-01 --updated-end-time=2030-02-02
    ...    OK: All jobs are ok
    ...    5
    ...    --include-cluster=abcdeff-xwxwxwxw-xwxwxw-xwxwxw-xwxwxw
    ...    OK:
    ...    6
    ...    --updated-last=9999d
    ...    OK: All jobs are ok
    ...    7
    ...    --job-name=1
    ...    OK: All jobs are ok
    ...    8
    ...    --job-type=1
    ...    OK: All jobs are ok
    ...    9
    ...    --job-status=1
    ...    OK: All jobs are ok
    ...    10
    ...    --object-type=1
    ...    OK: All jobs are ok
    ...    11
    ...    --include-job-id=22
    ...    OK:
    ...    12
    ...    --exclude-job-id=22
    ...    OK: All jobs are ok
    ...    13
    ...    --include-job-name=TESTID
    ...    OK: All jobs are ok
    ...    14
    ...    --exclude-job-name=TESTID
    ...    OK:
    ...    15
    ...    --include-job-type=FILE
    ...    OK:
    ...    16
    ...    --exclude-job-type=FILE
    ...    OK: All jobs are ok
    ...    17
    ...    --include-job-status=none
    ...    OK:
    ...    18
    ...    --exclude-job-status=Success
    ...    OK: job 'TESTID
    ...    19
    ...    --include-object-type=1
    ...    OK:
    ...    20
    ...    --exclude-object-type=1
    ...    OK: All jobs are ok
    ...    21
    ...    --include-location=test
    ...    OK: All jobs are ok
    ...    22
    ...    --exclude-location=test
    ...    OK:
    ...    23
    ...    --unknown-execution-status='%\\\{status\\\}=~/Success/i'
    ...    UNKNOWN: job 'TESTID:
    ...    24
    ...    --warning-execution-status='%\\\{status\\\}=~/Success/i'
    ...    WARNING: job 'TESTID:
    ...    25
    ...    --critical-execution-status='%\\\{status\\\}=~/Success/i'
    ...    CRITICAL: job 'TESTID:
    ...    26
    ...    --warning-job-execution-last=1
    ...    WARNING: job 'TESTID:
    ...    27
    ...    --critical-job-execution-last=1
    ...    CRITICAL: job 'TESTID:
    ...    28
    ...    --warning-job-executions-failed-prct=1:
    ...    WARNING: job 'TESTID:
    ...    29
    ...    --critical-job-executions-failed-prct=1:
    ...    CRITICAL: job 'TESTID:
    ...    30
    ...    --warning-job-running-duration=1
    ...    WARNING: job 'TESTID:
    ...    31
    ...    --critical-job-running-duration=1
    ...    CRITICAL: job 'TESTID:
    ...    32
    ...    --warning-jobs-executions-detected=1
    ...    WARNING: Number of jobs executions detected: 2
    ...    33
    ...    --critical-jobs-executions-detected=1
    ...    CRITICAL: Number of jobs executions detected: 2
    ...    34
    ...    --disco-show
    ...    label jobId="Fileset:::zazaza-zzzazza-dsdsdds-sdsdsd-sddssdsd"
    ...    35
    ...    --disco-format
    ...    <element>jobId</element>
