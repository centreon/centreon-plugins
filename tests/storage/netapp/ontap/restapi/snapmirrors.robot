*** Settings ***
Documentation       Netapp Ontap Restapi Snapmirrors plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}netapp.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=storage::netapp::ontap::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=username
...                 --api-password=password
...                 --mode=snapmirrors


*** Test Cases ***
Snapmirrors ${tc}
    [Tags]    storage    netapp    ontapp    api    snapmirrors    mockoon
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                      expected_result    --
            ...       1   --critical-status=''                                               OK: Snapmirror 'svm1:volume1-svm1:volume1' healthy: false [state: snapmirrored] [transfer state: string]
            ...       2   ${EMPTY}                                                           CRITICAL: Snapmirror 'svm1:volume1-svm1:volume1' healthy: false [state: snapmirrored] [transfer state: string]
            ...       3   --warning-status='\\\%{healthy} ne "true"' --critical-status=''     WARNING: Snapmirror 'svm1:volume1-svm1:volume1' healthy: false [state: snapmirrored] [transfer state: string]
