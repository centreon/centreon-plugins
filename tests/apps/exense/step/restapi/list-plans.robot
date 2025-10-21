*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::exense::step::restapi::plugin
...                 --mode=list-plans
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --timeout=15
...                 --token=token   


*** Test Cases ***
list-plans ${tc}
    [Tags]    apps    
    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extraoptions                                                                               expected_result    --
            ...       1   ${EMPTY}                                                                                   List plans: [id: 66d1904664e24c6ef10f74d2][name: plop2-test] [id: 669fc855498c2a0322a6a9c5][name: test-plan] [id: 66d180a764e24c6ef10e0155][name: test-plan_Copy]  
            ...       2   --tenant-name='[All]'                                                                      List plans: [id: 66d1904664e24c6ef10f74d2][name: plop2-test] [id: 669fc855498c2a0322a6a9c5][name: test-plan] [id: 66d180a764e24c6ef10e0155][name: test-plan_Copy]
