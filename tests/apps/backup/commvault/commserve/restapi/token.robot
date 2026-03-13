*** Settings ***
Documentation       Check Commvault REST API Check

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
...                 --api-token='T@k3n'
...                 --refresh-token='R3fR3sHt@K3n'
...                 --proto='http'
...                 --mode=token
...                 --port=${APIPORT}


*** Test Cases ***
jobs ${tc}
    [Tags]    apps    backup    commvalt    commserve    restapi

    ${command}    Catenate
    ...    ${CMD}

    ${command}    Catenate    ${CMD} --http-backend=curl ${extraoptions}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:        tc    extra_options                    expected_regexp    --
            ...      1     ${EMPTY}                         ^OK: Token
