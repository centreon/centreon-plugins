*** Settings ***
Documentation       Check the hosts mode with api custom mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}ansible_tower.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::automation::ansible::tower::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --username=username
...                 --password=password
...                 --port=${APIPORT}


*** Test Cases ***
Hosts ${tc}
    [Documentation]    Check the number of returned hosts
    [Tags]    apps    automation    ansible    service-disco
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hosts
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${expected_result}
    ...    ${output}
    ...    Wrong output result for command:{\n}{\n}${command}{\n}{\n}Command output:{\n}{\n}${output}

    Examples:         tc  snmpcommunity                     expected_result    --
            ...       1   os/linux/snmp/list-diskio         OK: Hosts total: 10, failed: 0 - All hosts are ok | 'hosts.total.count'=10;;;0; 'hosts.failed.count'=0;;;0;10
