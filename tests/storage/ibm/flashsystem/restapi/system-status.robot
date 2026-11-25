*** Settings ***
Documentation     storage::ibm::flashsystem::restapi::plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}flashsystem.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=storage::ibm::flashsystem::restapi::plugin
...                --mode=system-status
...                --hostname=${HOSTNAME}
...                --proto=http
...                --port=${APIPORT}
...                --api-username=user
...                --api-password=pass
...                --statefile-dir=/tmp


*** Test Cases ***
system-status ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
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
    ...    OK: Array canisters online: 2/2, pools online: 1/1 | 'system.canisters.online.count'=2;;1:;0;2 'system.pools.online.count'=1;;1:;0;1
    ...    2
    ...    --critical-canisters-online=3:
    ...    CRITICAL: Array canisters online: 2/2 | 'system.canisters.online.count'=2;;3:;0;2 'system.pools.online.count'=1;;1:;0;1
    ...    3
    ...    --warning-pools-online=2:
    ...    WARNING: Array pools online: 1/1 | 'system.canisters.online.count'=2;;1:;0;2 'system.pools.online.count'=1;2:;1:;0;1

system-status command cache
    [Documentation]    The second and third runs target an API path the mock does not serve.
    [Tags]    storage    ibm    flashsystem    restapi
    Remove File    /tmp/ibm_flashsystem_api_rsp_*

    ${command}    Catenate    ${CMD}    --command-cache-ttl=60
    Ctn Run Command And Check Result As Strings
    ...    ${command}
    ...    OK: Array canisters online: 2/2, pools online: 1/1 | 'system.canisters.online.count'=2;;1:;0;2 'system.pools.online.count'=1;;1:;0;1

    ${command}    Catenate    ${CMD}    --command-cache-ttl=60    --api-path=/nonexistent
    Ctn Run Command And Check Result As Strings
    ...    ${command}
    ...    OK: Array canisters online: 2/2, pools online: 1/1 | 'system.canisters.online.count'=2;;1:;0;2 'system.pools.online.count'=1;;1:;0;1

    ${command}    Catenate    ${CMD}    --command-cache-ttl=0    --api-path=/nonexistent
    Ctn Run Command And Check Result As Regexp
    ...    ${command}
    ...    ^UNKNOWN: API command '\\S+' failed: HTTP 404
