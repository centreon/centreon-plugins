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
    ...    OK: All apps are ok | 'Outlook Online#application.total-users.count'=67;;;0; 'Outlook Online#application.score.value'=81;;;0;100 'Outlook Online#application.page-fetch-time.milliseconds'=148.22ms;;;0; 'SharePoint Online#application.total-users.count'=50;;;0; 'SharePoint Online#application.score.value'=73;;;0;100 'SharePoint Online#application.page-fetch-time.milliseconds'=641.69ms;;;0;
    ...    2
    ...    --application-id=3
    ...    OK: App "Outlook Online" - Users count: 55, Score: 99, Page fetch time: 148.22ms | 'Outlook Online#application.total-users.count'=55;;;0; 'Outlook Online#application.score.value'=99;;;0;100 'Outlook Online#application.page-fetch-time.milliseconds'=148.22ms;;;0;
    ...    3
    ...    --application-id=3 --warning-score=1
    ...    WARNING: App "Outlook Online" - Score: 99 | 'Outlook Online#application.total-users.count'=55;;;0; 'Outlook Online#application.score.value'=99;0:1;;0;100 'Outlook Online#application.page-fetch-time.milliseconds'=148.22ms;;;0;
    ...    4
    ...    --application-id=3 --critical-score=1
    ...    CRITICAL: App "Outlook Online" - Score: 99 | 'Outlook Online#application.total-users.count'=55;;;0; 'Outlook Online#application.score.value'=99;;0:1;0;100 'Outlook Online#application.page-fetch-time.milliseconds'=148.22ms;;;0;
    ...    5
    ...    --application-id=3 --warning-total-users=1
    ...    WARNING: App "Outlook Online" - Users count: 55 | 'Outlook Online#application.total-users.count'=55;0:1;;0; 'Outlook Online#application.score.value'=99;;;0;100 'Outlook Online#application.page-fetch-time.milliseconds'=148.22ms;;;0;
    ...    6
    ...    --application-id=3 --critical-total-users=1
    ...    CRITICAL: App "Outlook Online" - Users count: 55 | 'Outlook Online#application.total-users.count'=55;;0:1;0; 'Outlook Online#application.score.value'=99;;;0;100 'Outlook Online#application.page-fetch-time.milliseconds'=148.22ms;;;0;
    ...    7
    ...    --include-application-name=SharePoint
    ...    OK: App "SharePoint Online" - Users count: 50, Score: 73, Page fetch time: 641.69ms | 'SharePoint Online#application.total-users.count'=50;;;0; 'SharePoint Online#application.score.value'=73;;;0;100 'SharePoint Online#application.page-fetch-time.milliseconds'=641.69ms;;;0;
    ...    8
    ...    --exclude-application-name=SharePoint
    ...    OK: App "Outlook Online" - Users count: 67, Score: 81, Page fetch time: 148.22ms | 'Outlook Online#application.total-users.count'=67;;;0; 'Outlook Online#application.score.value'=81;;;0;100 'Outlook Online#application.page-fetch-time.milliseconds'=148.22ms;;;0;
    ...    9
    ...    --application-id=3 --include-location-name=Road
    ...    OK: App "Outlook Online" - Users count: 55, Score: 99, Page fetch time: 148.22ms | 'Outlook Online#application.total-users.count'=55;;;0; 'Outlook Online#application.score.value'=99;;;0;100 'Outlook Online#application.page-fetch-time.milliseconds'=148.22ms;;;0;
    ...    10
    ...    --application-id=3 --exclude-location-name=Road
    ...    OK: App "Outlook Online" - Users count: 55, Score: 99 | 'Outlook Online#application.total-users.count'=55;;;0; 'Outlook Online#application.score.value'=99;;;0;100
    ...    11
    ...    --application-id=3 --location-id=73260557
    ...    OK: App "Outlook Online" - Users count: 55, Score: 99 | 'Outlook Online#application.total-users.count'=55;;;0; 'Outlook Online#application.score.value'=99;;;0;100
    ...    12
    ...    --application-id=3 --location-id=4294967293
    ...    OK: App "Outlook Online" - Users count: 55, Score: 99, Page fetch time: 148.22ms | 'Outlook Online#application.total-users.count'=55;;;0; 'Outlook Online#application.score.value'=99;;;0;100 'Outlook Online#application.page-fetch-time.milliseconds'=148.22ms;;;0;
    ...    13
    ...    --include-application-name=SharePoint --warning-page-fetch-time=100
    ...    WARNING: App "SharePoint Online" - Page fetch time: 641.69ms | 'SharePoint Online#application.total-users.count'=50;;;0; 'SharePoint Online#application.score.value'=73;;;0;100 'SharePoint Online#application.page-fetch-time.milliseconds'=641.69ms;0:100;;0;
    ...    14
    ...    --include-application-name=SharePoint --critical-page-fetch-time=100
    ...    CRITICAL: App "SharePoint Online" - Page fetch time: 641.69ms | 'SharePoint Online#application.total-users.count'=50;;;0; 'SharePoint Online#application.score.value'=73;;;0;100 'SharePoint Online#application.page-fetch-time.milliseconds'=641.69ms;;0:100;0;
