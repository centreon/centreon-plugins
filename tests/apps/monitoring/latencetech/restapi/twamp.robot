*** Settings ***
Documentation       Check the LatenceTech twamp mode with api custom mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::latencetech::restapi::plugin
...                 --custommode=api
...                 --mode=twamp
...                 --hostname=${HOSTNAME}
...                 --api-key=key
...                 --port=${APIPORT}
...                 --proto=http


*** Test Cases ***
Twamp ${tc}
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
            ...       OK: Agent '2' TWAMP Forward Delta: 12.92ms, TWAMP Reverse Delta: -4.19ms, TWAMP Processing Delta: 0.11ms | '2#twamp.forwarddelta.time.milliseconds'=12.92ms;;;0; '2#twamp.reversedelta.time.milliseconds'=-4.19ms;;;0; '2#twamp.processingdelta.time.milliseconds'=0.11ms;;;0;
            ...       2     --warning-twamp-forward=10
            ...       WARNING: Agent '2' TWAMP Forward Delta: 12.92ms | '2#twamp.forwarddelta.time.milliseconds'=12.92ms;0:10;;0; '2#twamp.reversedelta.time.milliseconds'=-4.19ms;;;0; '2#twamp.processingdelta.time.milliseconds'=0.11ms;;;0;
            ...       3     --critical-twamp-forward=12.5
            ...       CRITICAL: Agent '2' TWAMP Forward Delta: 12.92ms | '2#twamp.forwarddelta.time.milliseconds'=12.92ms;;0:12.5;0; '2#twamp.reversedelta.time.milliseconds'=-4.19ms;;;0; '2#twamp.processingdelta.time.milliseconds'=0.11ms;;;0;
            ...       4     --warning-twamp-reverse=-4.5
            ...       WARNING: Agent '2' TWAMP Reverse Delta: -4.19ms | '2#twamp.forwarddelta.time.milliseconds'=12.92ms;;;0; '2#twamp.reversedelta.time.milliseconds'=-4.19ms;0:-4.5;;0; '2#twamp.processingdelta.time.milliseconds'=0.11ms;;;0;
            ...       5     --critical-twamp-reverse=-5
            ...       CRITICAL: Agent '2' TWAMP Reverse Delta: -4.19ms | '2#twamp.forwarddelta.time.milliseconds'=12.92ms;;;0; '2#twamp.reversedelta.time.milliseconds'=-4.19ms;;0:-5;0; '2#twamp.processingdelta.time.milliseconds'=0.11ms;;;0;
            ...       6     --warning-twamp-processing=0.05
            ...       WARNING: Agent '2' TWAMP Processing Delta: 0.11ms | '2#twamp.forwarddelta.time.milliseconds'=12.92ms;;;0; '2#twamp.reversedelta.time.milliseconds'=-4.19ms;;;0; '2#twamp.processingdelta.time.milliseconds'=0.11ms;0:0.05;;0;
            ...       7     --critical-twamp-processing=0.1
            ...       CRITICAL: Agent '2' TWAMP Processing Delta: 0.11ms | '2#twamp.forwarddelta.time.milliseconds'=12.92ms;;;0; '2#twamp.reversedelta.time.milliseconds'=-4.19ms;;;0; '2#twamp.processingdelta.time.milliseconds'=0.11ms;;0:0.1;0;
