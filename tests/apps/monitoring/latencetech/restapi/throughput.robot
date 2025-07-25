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
    ...          OK: Agent '2' LifBE Download: 531.58mbps, LifBE Upload: 47.05mbps, Jitter Download Time: 1.17ms, Jitter Upload Time: 3.38ms | '2#lifbe.download.bandwidth.mbps'=531.58mbps;;;0; '2#lifbe.upload.bandwidth.mbps'=47.05mbps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          2     --warning-lifbe-download=500
    ...          WARNING: Agent '2' LifBE Download: 531.58mbps | '2#lifbe.download.bandwidth.mbps'=531.58mbps;0:500;;0; '2#lifbe.upload.bandwidth.mbps'=47.05mbps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          3     --critical-lifbe-download=450
    ...          CRITICAL: Agent '2' LifBE Download: 531.58mbps | '2#lifbe.download.bandwidth.mbps'=531.58mbps;;0:450;0; '2#lifbe.upload.bandwidth.mbps'=47.05mbps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          4     --warning-lifbe-upload=45
    ...          WARNING: Agent '2' LifBE Upload: 47.05mbps | '2#lifbe.download.bandwidth.mbps'=531.58mbps;;;0; '2#lifbe.upload.bandwidth.mbps'=47.05mbps;0:45;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          5     --critical-lifbe-upload=40
    ...          CRITICAL: Agent '2' LifBE Upload: 47.05mbps | '2#lifbe.download.bandwidth.mbps'=531.58mbps;;;0; '2#lifbe.upload.bandwidth.mbps'=47.05mbps;;0:40;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          6     --warning-jitter-download=0.9
    ...          WARNING: Agent '2' Jitter Download Time: 1.17ms | '2#lifbe.download.bandwidth.mbps'=531.58mbps;;;0; '2#lifbe.upload.bandwidth.mbps'=47.05mbps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;0:0.9;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          7     --critical-jitter-download=1.1
    ...          CRITICAL: Agent '2' Jitter Download Time: 1.17ms | '2#lifbe.download.bandwidth.mbps'=531.58mbps;;;0; '2#lifbe.upload.bandwidth.mbps'=47.05mbps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;0:1.1;0; '2#jitter.upload.time.milliseconds'=3.38ms;;;0;
    ...          8     --warning-jitter-upload=3
    ...          WARNING: Agent '2' Jitter Upload Time: 3.38ms | '2#lifbe.download.bandwidth.mbps'=531.58mbps;;;0; '2#lifbe.upload.bandwidth.mbps'=47.05mbps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;0:3;;0;
    ...          9     --critical-jitter-upload=3.25
    ...          CRITICAL: Agent '2' Jitter Upload Time: 3.38ms | '2#lifbe.download.bandwidth.mbps'=531.58mbps;;;0; '2#lifbe.upload.bandwidth.mbps'=47.05mbps;;;0; '2#jitter.download.time.milliseconds'=1.17ms;;;0; '2#jitter.upload.time.milliseconds'=3.38ms;;0:3.25;0;
