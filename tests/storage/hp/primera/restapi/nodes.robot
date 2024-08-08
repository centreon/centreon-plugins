*** Settings ***
Documentation       HPE Primera Storage REST API

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}hpe-primera.mockoon.json
${HOSTNAME}             127.0.0.1
${APIPORT}              3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=storage::hp::primera::restapi::plugin
...                 --mode=nodes
...                 --hostname=${HOSTNAME}
...                 --api-username=toto
...                 --api-password=toto
...                 --proto=http
...                 --port=${APIPORT}
...                 --custommode=api
...                 --statefile-dir=/dev/shm/

*** Test Cases ***
Nodes ${tc}
    [Tags]    storage     api    hpe    hp
    ${output}    Run    ${CMD} ${extraoptions}

    ${output}    Strip String    ${output}

    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${CMD} ${extraoptions}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

    Examples:    tc        extraoptions                                                     expected_result   --
        ...      1        ${EMPTY}                                                          WARNING: node 0 is offline | 'nodes.total.count'=2;;;0; 'nodes.online.count'=1;;;0;2 'nodes.offline.count'=1;;;0;2
        ...      2        --warning-node-status='${PERCENT}\\{status\\} ne "offline"'       WARNING: node 1 is online | 'nodes.total.count'=2;;;0; 'nodes.online.count'=1;;;0;2 'nodes.offline.count'=1;;;0;2
        ...      3        --warning-online=2:2                                              WARNING: Number of online nodes: 1 - node 0 is offline | 'nodes.total.count'=2;;;0; 'nodes.online.count'=1;2:2;;0;2 'nodes.offline.count'=1;;;0;2
        ...      4        --critical-online=2:2                                             CRITICAL: Number of online nodes: 1 WARNING: node 0 is offline | 'nodes.total.count'=2;;;0; 'nodes.online.count'=1;;2:2;0;2 'nodes.offline.count'=1;;;0;2
        ...      5        --critical-offline=0:0                                            CRITICAL: Number of offline nodes: 1 WARNING: node 0 is offline | 'nodes.total.count'=2;;;0; 'nodes.online.count'=1;;;0;2 'nodes.offline.count'=1;;0:0;0;2
