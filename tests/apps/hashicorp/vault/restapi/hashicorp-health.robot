*** Settings ***
Documentation       HashiCorp Vault REST API Health Check

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}hashicorp-health.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=apps::hashicorp::vault::restapi::plugin
...                 --mode health
...                 --hostname=${HOSTNAME}
...                 --vault-token=xx-xxx
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
Health ${tc}
    [Tags]    apps    hashicorp    vault    restapi    mockoon   
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:         tc  extra_options                                                                      expected_result    --
            ...       1   ${EMPTY}                                                                           OK: Server test-cluster-master seal status : unsealed, init status : initialized, standby status : false
            ...       2   --warning-init-status='\\%\{init\} ne "initialized"' --critical-init-status=''     WARNING: Server test-cluster-uninit init status : not initialized
            ...       3   ${EMPTY}                                                                           OK: Server test-cluster-standby seal status : unsealed, init status : initialized, standby status : true
            ...       4   --warning-seal-status='\\%\{init\} ne "sealed"' --critical-seal-status=''          WARNING: Server test-cluster-sealed seal status : sealed
            ...       5   ${EMPTY}                                                                           CRITICAL: Server test-cluster-uninitstandby init status : not initialized
            ...       6   --standbycode=508                                                                  UNKNOWN: 508 Loop Detected
            ...       7   --performancestandbycode=524                                                       UNKNOWN: 524 unknown
            ...       8   --critical-standby-status='\\%\{standby\} ne "false"'                              CRITICAL: Server test-cluster-standby2 standby status : true
