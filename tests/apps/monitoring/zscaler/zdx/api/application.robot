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
    ...    OK: All apps are ok | 'appli_18#application.total-users.count'=1385;;;0; 'appli_18#application.score.value'=85;;;; 'appli_42#application.total-users.count'=1139;;;0; 'appli_42#application.score.value'=39;;;;
    ...    2
    ...    --application-id=42
    ...    OK: App "appli_42" - Users count: 1139, Score: 39 | 'appli_42#application.total-users.count'=1139;;;0; 'appli_42#application.score.value'=39;;;;
    ...    3
    ...    --application-id=42 --warning-score=1
    ...    WARNING: App "appli_42" - Score: 39 | 'appli_42#application.total-users.count'=1139;;;0; 'appli_42#application.score.value'=39;0:1;;;
    ...    4
    ...    --application-id=42 --critical-score=1
    ...    CRITICAL: App "appli_42" - Score: 39 | 'appli_42#application.total-users.count'=1139;;;0; 'appli_42#application.score.value'=39;;0:1;;
    ...    5
    ...    --application-id=42 --warning-total-users=1
    ...    WARNING: App "appli_42" - Users count: 1139 | 'appli_42#application.total-users.count'=1139;0:1;;0; 'appli_42#application.score.value'=39;;;;
    ...    6
    ...    --application-id=42 --critical-total-users=1
    ...    CRITICAL: App "appli_42" - Users count: 1139 | 'appli_42#application.total-users.count'=1139;;0:1;0; 'appli_42#application.score.value'=39;;;;
    ...    7
    ...    --include-application-name=1
    ...    OK: App "appli_18" - Users count: 1385, Score: 85 | 'appli_18#application.total-users.count'=1385;;;0; 'appli_18#application.score.value'=85;;;;
    ...    8
    ...    --exclude-application-name=1
    ...    OK: App "appli_42" - Users count: 1139, Score: 39 | 'appli_42#application.total-users.count'=1139;;;0; 'appli_42#application.score.value'=39;;;;
