*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::exense::step::restapi::plugin
...                 --mode=list-tenants
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --timeout=15
...                 --token=token   


*** Test Cases ***
list-tenants ${tc}
    [Tags]    apps    
    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:         tc  extraoptions                       expected_result    --
            ...       1   ${EMPTY}                           List tenants: [name: [All]][projectId: ][global: 1] [name: Common][projectId: 669fc509498c2a0322a6a5ad][global: 0] [name: test-project][projectId: 66d18fc464e24c6ef10f6f02][global: 0]  
