*** Settings ***
Documentation       Netapp Ontap Restapi Luns plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}netapp.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=storage::netapp::ontap::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=username
...                 --api-password=password
...                 --mode=luns


*** Test Cases ***
Luns ${tc}
    [Tags]    storage    netapp    ontapp    api    luns    mockoon   
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:         tc  extra_options                                      expected_result    --
            ...       1   ${EMPTY}                                           OK: Lun '/vol/volume1/qtree1/lun1' state: online [container state: string]
            ...       2   --warning-status='\\\%{state} !~ /notonline/i'     WARNING: Lun '/vol/volume1/qtree1/lun1' state: online [container state: string]
            ...       3   --critical-status='\\\%{state} !~ /notonline/i'    CRITICAL: Lun '/vol/volume1/qtree1/lun1' state: online [container state: string]
