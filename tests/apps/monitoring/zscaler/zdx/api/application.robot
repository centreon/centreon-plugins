*** Settings ***
Documentation       apps::monitoring::zscaler::zdx::api::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...         --plugin=apps::monitoring::zscaler::zdx::api::plugin
...         --mode=application
...         --hostname=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --key-id=1
...         --key-secret=1


*** Test Cases ***
Application ${tc}
    [Tags]    apps    monitoring    api
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
    ...    UNKNOWN: Option application_id cannot be empty
    ...    2
    ...    --application-id=42
    ...    OK: App "Microsoft Teams Call Quality": Users count: 1345, Score: 85 | 'application.total-users.count'=1345;;;0; 'application.score.value'=85;;;;
    ...    3
    ...    --application-id=42 --warning-score=1
    ...    WARNING: App "Microsoft Teams Call Quality": Score: 85 | 'application.total-users.count'=1345;;;0; 'application.score.value'=85;0:1;;;
    ...    4
    ...    --application-id=42 --critical-score=1
    ...    CRITICAL: App "Microsoft Teams Call Quality": Score: 85 | 'application.total-users.count'=1345;;;0; 'application.score.value'=85;;0:1;;
    ...    5
    ...    --application-id=42 --warning-total-users=1
    ...    WARNING: App "Microsoft Teams Call Quality": Users count: 1345 | 'application.total-users.count'=1345;0:1;;0; 'application.score.value'=85;;;;
    ...    6
    ...    --application-id=42 --critical-total-users=1
    ...    CRITICAL: App "Microsoft Teams Call Quality": Users count: 1345 | 'application.total-users.count'=1345;;0:1;0; 'application.score.value'=85;;;;
