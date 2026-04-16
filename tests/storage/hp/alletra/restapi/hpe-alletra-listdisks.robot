*** Settings ***
Documentation       HPE Alletra Storage REST API Mode List Disks

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}hpe-alletra.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::hp::alletra::restapi::plugin
...                 --mode list-disks
...                 --hostname=${HOSTNAME}
...                 --api-username=xx
...                 --api-password=xx
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
ListDisks ${tc}
    [Tags]    storage    api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:        tc       extraoptions                                                              expected_regexp    --
            ...      1        ${EMPTY}                                                                  ^Disks: (\\\\n\\\\[id:.*\\\\]){3}\\\\Z
            ...      2        --filter-type=SLC                                                         ^Disks: (\\\\n\\\\[id:.*\\\\]){1}\\\\Z
            ...      3        --filter-id=1                                                             ^Disks: (\\\\n\\\\[id:.*\\\\]){1}\\\\Z
            ...      4        --filter-protocol=SATA                                                    ^Disks: (\\\\n\\\\[id:.*\\\\]){1}\\\\Z
