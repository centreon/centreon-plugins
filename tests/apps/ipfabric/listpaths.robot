*** Settings ***
Documentation       IPFabric plugin
Resource            ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}ipfabric.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::ipfabric::plugin
...                 --api-key=EEECGFCGFCGF
...                 --mode=list-paths
...                 --hostname=${HOSTNAME}
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
ListPaths ${tc}
    [Tags]    apps    api    ipfabric
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:         tc  extra_options                              expected_result    --
            ...       1   ${EMPTY}                                   (?s)^List paths:.*\\\\[id: A1020\\\\]
