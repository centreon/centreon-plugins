*** Settings ***
Documentation     HP ILO Restapi Hardware plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}hp_ilo_restapi.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=hardware::server::hp::ilo::restapi::plugin
...                --hostname=${HOSTNAME}
...                --port=${APIPORT}
...                --proto=http
...                --api-username=toto
...                --api-password=toto
...                --mode=hardware


*** Test Cases ***
Hardware ${tc}
    [Tags]    hardware    server    hp    ilo    api    mockoon
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc    extra_options    expected_result    --
    ...    1
    ...    --component='drive'
    ...    OK: All 5 components are ok [5/5 drives]. | 'hardware.drive.count'=5;;;;
    ...    2
    ...    --component='sc'
    ...    WARNING: Storage controller 'system:FGHIJ456/1/0' status is 'Warning' | 'hardware.sc.count'=3;;;;
    ...    3
    ...    --component='storage'
    ...    OK: All 3 components are ok [3/3 storages]. | 'hardware.storage.count'=3;;;;
    ...    4
    ...    --component='volume'
    ...    OK: All 3 components are ok [3/3 volumes]. | 'hardware.volume.count'=3;;;;
    ...    5
    ...    --component='sc' --filter='sc,FGHIJ456.1.0'
    ...    OK: All 2 components are ok [2/2 sc]. | 'hardware.sc.count'=2;;;;
