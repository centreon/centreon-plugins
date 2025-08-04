*** Settings ***
Documentation       Check the LatenceTech throughput mode with api custom mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::latencetech::restapi::plugin
...                 --custommode=api
...                 --mode=throughput
...                 --hostname=${HOSTNAME}
...                 --api-key=key
...                 --port=${APIPORT}
...                 --proto=http

*** Test Cases ***
Throughput ${tc}
    [Documentation]    Check agent throughput statistics.
    [Tags]    apps    monitoring    latencetech    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --customer-id=0
    ...    --agent-id=2
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions    expected_result    --
    ...          1     ${EMPTY}
    ...          OK: Agent '2' LIFBE Download: 531.58Mbps, LIFBE Upload: 47.05Mbps, Jitter Download Time: 1.17ms, Jitter Upload Time: 3.38ms | '2#lifbe.download.bandwidth.bps'=531580000bps;;;0; '2#lifbe.upload.bandwidth.bps'=47050000bps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          2     --warning-lifbe-download=500
    ...          WARNING: Agent '2' LIFBE Download: 531.58Mbps | '2#lifbe.download.bandwidth.bps'=531580000bps;0:500;;0; '2#lifbe.upload.bandwidth.bps'=47050000bps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          3     --critical-lifbe-download=450
    ...          CRITICAL: Agent '2' LIFBE Download: 531.58Mbps | '2#lifbe.download.bandwidth.bps'=531580000bps;;0:450;0; '2#lifbe.upload.bandwidth.bps'=47050000bps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          4     --warning-lifbe-upload=45000000
    ...          WARNING: Agent '2' LIFBE Upload: 47.05Mbps | '2#lifbe.download.bandwidth.bps'=531580000bps;;;0; '2#lifbe.upload.bandwidth.bps'=47050000bps;0:45000000;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          5     --critical-lifbe-upload=40000000
    ...          CRITICAL: Agent '2' LIFBE Upload: 47.05Mbps | '2#lifbe.download.bandwidth.bps'=531580000bps;;;0; '2#lifbe.upload.bandwidth.bps'=47050000bps;;0:40000000;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          6     --critical-lifbe-upload=48000000
    ...          OK: Agent '2' LIFBE Download: 531.58Mbps, LIFBE Upload: 47.05Mbps, Jitter Download Time: 1.17ms, Jitter Upload Time: 3.38ms | '2#lifbe.download.bandwidth.bps'=531580000bps;;;0; '2#lifbe.upload.bandwidth.bps'=47050000bps;;0:48000000;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          7     --warning-jitter-download=0.9
    ...          WARNING: Agent '2' Jitter Download Time: 1.17ms | '2#lifbe.download.bandwidth.bps'=531580000bps;;;0; '2#lifbe.upload.bandwidth.bps'=47050000bps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;0:0.9;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          8     --critical-jitter-download=1.1
    ...          CRITICAL: Agent '2' Jitter Download Time: 1.17ms | '2#lifbe.download.bandwidth.bps'=531580000bps;;;0; '2#lifbe.upload.bandwidth.bps'=47050000bps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;0:1.1;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          9     --warning-jitter-upload=3
    ...          WARNING: Agent '2' Jitter Upload Time: 3.38ms | '2#lifbe.download.bandwidth.bps'=531580000bps;;;0; '2#lifbe.upload.bandwidth.bps'=47050000bps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;0:3;;0;
    ...          10    --critical-jitter-upload=3.25
    ...          CRITICAL: Agent '2' Jitter Upload Time: 3.38ms | '2#lifbe.download.bandwidth.bps'=531580000bps;;;0; '2#lifbe.upload.bandwidth.bps'=47050000bps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;0:3.25;0;
