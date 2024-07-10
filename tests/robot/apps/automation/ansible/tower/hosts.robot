*** Settings ***
Documentation       Check the hosts mode with api custom mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s

Test Setup       Set Test Variable      ${cnt}    ${1}
Test Teardown    Set Test Variable    ${cnt}    ${cnt + 1}



*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=apps::automation::ansible::tower::plugin
...         --custommode=api
...         --hostname=host.docker.internal
...         --username=username
...         --password=password
...         --port=3000


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
