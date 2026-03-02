*** Settings ***
Documentation       Check health mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}health.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::fortinet::fortigate::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --proto=http
...                 --access-token=mokoon-token
...                 --mode=health
...                 --port=${APIPORT}


*** Test Cases ***
health ${tc}
    [Tags]    network    fortinet    fortigate    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    # Mockoon endpoint is set to sequential so we need to run the same test twice to get the same result ( one time with hash and one time with array )

    Examples:         tc      extra_options                                           expected_result    --
            ...       1       ${EMPTY}                                                OK: vdom 'root1' health status: success
            ...       2       ${EMPTY}                                                OK: vdom 'root1' health status: success
            ...       3       --warning-health='\\\%{status} =~ /success/'            WARNING: vdom 'root1' health status: success
            ...       4       --warning-health='\\\%{status} =~ /success/'            WARNING: vdom 'root1' health status: success
            ...       5       --critical-health='\\\%{status} =~ /success/'           CRITICAL: vdom 'root1' health status: success
            ...       6       --critical-health='\\\%{status} =~ /success/'           CRITICAL: vdom 'root1' health status: success
