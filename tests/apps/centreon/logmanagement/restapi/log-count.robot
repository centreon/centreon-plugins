*** Settings ***
Documentation       apps::centreon::logmanagement::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::centreon::logmanagement::restapi::plugin
...                 --mode=log-count
...                 --hostname=${HOSTNAME}
...                 --org=org
...                 --proto=http
...                 --port=${APIPORT}
...                 --token=token
...                 --timeout=10
...                 --query=query


*** Test Cases ***
Log-count ${tc}
    [Tags]    apps    centreon    restapi
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
    ...    OK: Log count: 2 | 'log.count'=2;;;0;
    ...    2
    ...    --period=60
    ...    OK: Log count: 0 | 'log.count'=0;;;0;
    ...    3
    ...    --warning-count=1
    ...    WARNING: Log count: 2 | 'log.count'=2;0:1;;0;
    ...    4
    ...    --critical-count=1
    ...    CRITICAL: Log count: 2 | 'log.count'=2;;0:1;0;
    ...    5
    ...    --period=1
    ...    UNKNOWN: Bad value provided for option period: '1'. Constraint '1' greater_than_or_equal '60' is not verified.
    ...    6
    ...    --port=1000000
    ...    UNKNOWN: Bad value provided for option port: '1000000'. Constraint '1000000' less_than '65536' is not verified.
    ...    7
    ...    --proto=httpx
    ...    UNKNOWN: Bad value provided for option proto: 'httpx'. Constraint 'httpx' regexp_match '^http[s]?$' is not verified.
