*** Settings ***
Documentation       Check Commvault REST API Token management

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}commvault.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::commvault::commserve::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --mode=token
...                 --port=${APIPORT}


*** Test Cases ***
token ${tc}
    [Tags]    apps    backup    commvalt    commserve    restapi

    ${command}    Catenate
    ...    ${CMD}

    ${command}    Catenate    ${CMD} --http-backend=curl ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:       tc    extra_options                                                                       expected_result    --
    ...             1     ${EMPTY}                                                                            UNKNOWN: --api-token and --refresh-token are mandatory
    ...             2     --api-username=toto --api-password=ezeez                                            OK: Using username-based authentication
    ...             3     --api-token=XXXX --refresh-token=XXX --force-refresh                                OK: Token refreshed
    ...             4     --api-token=XXXX --refresh-token=XXX --refresh-token=99999                          OK: Token available
    ...             5     --api-token=XXXX --refresh-token=XXX --refresh-token=99999 --force-refresh          OK: Token refreshed
    ...             6     --api-username=toto --api-password=ezeez --status-if-unused='UNKNOWN'               UNKNOWN: Using username-based authentication
