*** Settings ***
Documentation       Check alerts.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mokoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::purestorage::flasharray::v2::restapi::plugin
...                 --hostname=host.docker.internal
...                 --proto='http'
...                 --api-version='2.4'
...                 --api-token='token'
...                 --port=3000
...                 --timeout='30'
...                 --insecure

*** Test Cases ***
alerts ${tc}
    [Documentation]    Check
    [Tags]    network    fortinet    fortigate    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=alerts
    ...    ${extra_options}
    Ctn Verify Command Output    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                              expected_result    --
            ...       1       --verbose --help                                                           lolipop
            ...       2       --verbose                                                                  CRITICAL: License
            ...       3       --filter-category                                                     WARNING: License
            ...       4       --warning-status                                                        WARNING: License
            ...       5       --critical-status                                                       CRITICAL: License
            ...       6       --memory                                                                CRITICAL: License