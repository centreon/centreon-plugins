*** Settings ***
Documentation       apps::voip::3cx::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${INJECT_PERL}      -Mfixed_date -I${CURDIR}
${MOCKOON_JSON}     ${CURDIR}${/}voip.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::voip::3cx::restapi::plugin
...                 --mode=extension
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=api-username
...                 --api-password=api-password
...                 --auth-mode=oauth2
...                 --timeout=10


*** Test Cases ***
Extension ${tc}
    [Tags]    apps    voip    restapi

    ${OLD_PERL5OPT}=    Get Environment Variable    PERL5OPT    default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

    ${command}=    Catenate
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
    ...    OK: All extensions are ok | '3cx.extensions.count'=3;;;0;
    ...    2
    ...    --include-extension=Centreon
    ...    OK: Extension '230 Centreon Test' registered, not in DND, Available, Talking since 11h 01m 42s | '3cx.extensions.count'=1;;;0;
    ...    3
    ...    --exclude-extension=Centreon
    ...    OK: All extensions are ok | '3cx.extensions.count'=2;;;0;
    ...    4
    ...    --dnd-profile-name=AA
    ...    OK: All extensions are ok | '3cx.extensions.count'=3;;;0;
    ...    5
    ...    --unknown-status='\\\%{status} =~ /Talking/'
    ...    UNKNOWN: Extension '230 Centreon Test' registered, not in DND, Available, Talking since 11h 01m 42s | '3cx.extensions.count'=3;;;0;
    ...    6
    ...    --warning-status='\\\%{status} =~ /Talking/'
    ...    WARNING: Extension '230 Centreon Test' registered, not in DND, Available, Talking since 11h 01m 42s | '3cx.extensions.count'=3;;;0;
    ...    7
    ...    --critical-status='\\\%{status} =~ /Talking/'
    ...    CRITICAL: Extension '230 Centreon Test' registered, not in DND, Available, Talking since 11h 01m 42s | '3cx.extensions.count'=3;;;0;
    ...    8
    ...    --warning-count=1
    ...    WARNING: Extensions count : 3 | '3cx.extensions.count'=3;0:1;;0;
    ...    9
    ...    --critical-count=1
    ...    CRITICAL: Extensions count : 3 | '3cx.extensions.count'=3;;0:1;0;
