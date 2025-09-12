*** Settings ***
Documentation       Cato Networks API Mode Dicovery

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
...                 --mode discovery
...                 --hostname=${HOSTNAME}
...                 --account-id=123
...                 --api-key=321
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
Discovery ${tc}
    [Tags]    network    securirt    api    graphql    cato
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}


    Examples:      tc    extraoptions                                        expected_regexp    --
          ...      1     ${EMPTY}                                            ^List sites: \\\\n\\\\[id: \\\\d+\\\\].+\\\\n\\\\[id: \\\\d+\\\\].+\\\\n\\\\[id: \\\\d+\\\\].+\\\\Z
          ...      2     --filter-site-name='Site Paris'                     ^List sites: \\\\n\\\\[id: 1001\\\\] \\\\[name: Site Paris
          ...      3     --filter-site-id='1002'                             ^List sites: \\\\n\\\\[id: 1002\\\\] \\\\[name: Site Toulouse
          ...      4     --connectivity-details=0                            ^List sites: \\\\n\\\\[id: \\\\d+\\\\].+\\\\[description: \\\\].+\\\\n\\\\[id: \\\\d+\\\\].+\\\\[description: \\\\].+\\\\n\\\\[id: \\\\d+\\\\].+\\\\[description: \\\\].+\\\\Z
