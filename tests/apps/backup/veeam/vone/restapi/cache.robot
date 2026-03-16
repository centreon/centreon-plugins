*** Settings ***
Documentation       apps::backup::veeam::vone::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vone.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...         --plugin=apps::backup::veeam::vone::restapi::plugin
...         --mode=cache
...         --hostname=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --api-username=UsErNaMe
...         --api-password=P@s$W0Rd


*** Test Cases ***
Cache ${tc}
    [Tags]    apps    backup    restapi
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
    ...    OK: Cache files created successfully
