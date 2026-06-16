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
...                 --mode=license
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=api-username
...                 --api-password=api-password
...                 --auth-mode=login
...                 --timeout=10


*** Test Cases ***
License ${tc}
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
    ...    OK: License active (expires on 2027-04-11T14:48:11Z), Support enabled (expires on 2027-04-11T14:48:11Z)
    ...    2
    ...    --warning-license='\\\%{expires_in} > 1'
    ...    WARNING: License active (expires on 2027-04-11T14:48:11Z)
    ...    3
    ...    --critical-license='\\\%{support} =~ /true/'
    ...    CRITICAL: License active (expires on 2027-04-11T14:48:11Z)
    ...    4
    ...    --warning-support='\\\%{maintenance_expires_in} > 1'
    ...    WARNING: Support enabled (expires on 2027-04-11T14:48:11Z)
    ...    5
    ...    --critical-support='\\\%{support} =~ /true/'
    ...    CRITICAL: Support enabled (expires on 2027-04-11T14:48:11Z)
