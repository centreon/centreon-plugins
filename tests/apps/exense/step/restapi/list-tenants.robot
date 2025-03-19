*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}list-tenants.json
${HOSTNAME}         host.docker.internal
${APIPORT}          3002

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::exense::step::restapi::plugin
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
    ...    --mode=list-tenants
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extraoptions                       expected_result    --
            ...       1   ${EMPTY}                           List tenants: [name: [All]][projectId: ][global: 1] [name: Common][projectId: 669fc509498c2a0322a6a5ad][global: 0] [name: test-project][projectId: 66d18fc464e24c6ef10f6f02][global: 0]  