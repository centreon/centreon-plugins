*** Settings ***
Documentation       apps::vmware::vsphere8::vcsa::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${INJECT_PERL}     -Mfixed_date -I${CURDIR}
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...         --plugin=apps::vmware::vsphere8::vcsa::plugin
...         --mode=updates
...         --http-peer-addr=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --username=1
...         --password=1


*** Test Cases ***
Updates ${tc}
    [Tags]    apps    vmware    vcsa

    ${OLD_PERL5OPT}=    Get Environment Variable     PERL5OPT   default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --hostname=UP_TO_DATE
    ...    OK: version '8.0.2.00500' is 'UP_TO_DATE', Last repository update was done 2024-10-22T11:39:06.803Z, 425 day(s) ago | 'repository.age.days'=425d;;;;
    ...    2
    ...    --hostname=UP_TO_DATE --warning-repository-age=1
    ...    WARNING: Last repository update was done 2024-10-22T11:39:06.803Z, 425 day(s) ago | 'repository.age.days'=425d;0:1;;;
    ...    3
    ...    --hostname=UP_TO_DATE --critical-repository-age=1
    ...    CRITICAL: Last repository update was done 2024-10-22T11:39:06.803Z, 425 day(s) ago | 'repository.age.days'=425d;;0:1;;
    ...    4
    ...    --hostname=INSTALL_IN_PROGRESS
    ...    WARNING: version '8.0.2.00500' is 'INSTALL_IN_PROGRESS' | 'repository.age.days'=425d;;;;
    ...    5
    ...    --hostname=INSTALL_FAILED
    ...    CRITICAL: version '8.0.2.00500' is 'INSTALL_FAILED' | 'repository.age.days'=425d;;;;
