*** Settings ***
Documentation       Cato Networks API Mode Connectivity

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}cato-api.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::security::cato::networks::api::plugin
...                 --mode connectivity
...                 --hostname=${HOSTNAME}
...                 --account-id=123
...                 --api-key=321
...                 --site-id=1001
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
Connecivity ${tc}
    [Tags]    network    securirt    api    graphql    cato
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}


    Examples:      tc    extraoptions                                        expected_regexp    --
          ...      1     ${EMPTY}                                            ^OK: connectivity-status : Connected
          ...      2     --filter-counters='connected'                       ^OK:
# More tests after first mode review
