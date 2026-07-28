*** Settings ***
Documentation       apps::thales::mistral::vs9::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mistral-mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::thales::mistral::vs9::restapi::plugin
...                 --mode=mmc-cluster
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=1
...                 --api-password=1


*** Test Cases ***
Mmc-cluster ${tc}
    [Tags]    apps    thales    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: cluster state: ok - all nodes are ok
    ...    2
    ...    --unknown-cluster-status=1
    ...    UNKNOWN: cluster state: ok
    ...    3
    ...    --warning-cluster-status=1
    ...    WARNING: cluster state: ok
    ...    4
    ...    --critical-cluster-status=1
    ...    CRITICAL: cluster state: ok
    ...    5
    ...    --unknown-node-status=1
    ...    UNKNOWN: node 'ANO-A.local' status: NONE - node 'ANO-B.local' status: PRIMARY
    ...    6
    ...    --warning-node-status=1
    ...    WARNING: node 'ANO-A.local' status: NONE - node 'ANO-B.local' status: PRIMARY
    ...    7
    ...    --critical-node-status=1
    ...    CRITICAL: node 'ANO-A.local' status: NONE - node 'ANO-B.local' status: PRIMARY
    ...    8
    ...    --warning-synchronization-done=1
    ...    OK: cluster state: ok - all nodes are ok
    ...    9
    ...    --critical-synchronization-done=1
    ...    OK: cluster state: ok - all nodes are ok
