*** Settings ***
Documentation       Netapp Ontap Restapi Hardware plugin

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
...                 --mode=hardware


*** Test Cases ***
Hardware ${tc}
    [Tags]    storage    netapp    ontapp    api    hardware    mockoon   
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:         tc  extra_options                            expected_result    --
            ...       1   ${EMPTY}                                 OK: All 4 components are ok [1/1 bays, 1/1 disks, 1/1 frus, 1/1 shelfs]. | 'hardware.bay.count'=1;;;; 'hardware.disk.count'=1;;;; 'hardware.fru.count'=1;;;; 'hardware.shelf.count'=1;;;;
            ...       2   --component='bay'                        OK: All 1 components are ok [1/1 bays]. | 'hardware.bay.count'=1;;;;
            ...       3   --component='disk'                       OK: All 1 components are ok [1/1 disks]. | 'hardware.disk.count'=1;;;;
            ...       4   --component='fru'                        OK: All 1 components are ok [1/1 frus]. | 'hardware.fru.count'=1;;;;
            ...       5   --component='shelf'                      OK: All 1 components are ok [1/1 shelfs]. | 'hardware.shelf.count'=1;;;;

