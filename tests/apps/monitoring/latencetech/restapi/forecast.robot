*** Settings ***
Documentation       Check the LatenceTech forecast mode with api custom mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::latencetech::restapi::plugin
...                 --custommode=api
...                 --mode=forecast
...                 --hostname=${HOSTNAME}
...                 --api-key=key
...                 --port=${APIPORT}
...                 --proto=http


*** Test Cases ***
forecast ${tc}
    [Documentation]    Check the agent forecast statistics
    [Tags]    apps    monitoring    latencetech    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --customer-id=0
    ...    --agent-id=2
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions    expected_result    --
            ...       1     ${EMPTY}
            ...       OK: Agent '2' Projected latency 10.63ms (forecasting interval: 6.94ms, confidence level: 50.74) | '2#latency.projected.time.milliseconds'=10.63ms;;;0;
            ...       2     --warning-projected-latency=5
            ...       WARNING: Agent '2' Projected latency 10.63ms (forecasting interval: 6.94ms, confidence level: 50.74) | '2#latency.projected.time.milliseconds'=10.63ms;0:5;;0;
            ...       3     --critical-projected-latency=10
            ...       CRITICAL: Agent '2' Projected latency 10.63ms (forecasting interval: 6.94ms, confidence level: 50.74) | '2#latency.projected.time.milliseconds'=10.63ms;;0:10;0;
