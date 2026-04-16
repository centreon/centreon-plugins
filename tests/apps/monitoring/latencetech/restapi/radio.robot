*** Settings ***
Documentation       Check the LatenceTech radio mode with api custom mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::latencetech::restapi::plugin
...                 --custommode=api
...                 --mode=radio
...                 --hostname=${HOSTNAME}
...                 --api-key=key
...                 --port=${APIPORT}
...                 --proto=http


*** Test Cases ***
Radio ${tc}
    [Documentation]    Check the agent radio statistics.
    [Tags]    apps    monitoring    latencetech    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --customer-id=0
    ...    --agent-id=1
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions    expected_result    --
            ...       1     ${EMPTY}
            ...       OK: Agent '1' Signal noise ratio: 2.15db, Received Signal Strength Indicator: -63.00dbm, Reference signal receive power: -10.00dbm, Reference signal receive quality: -94.00db | '1#signal.noise.ratio.db'=2.15dbm;;;; '1#received.signalstrength.indicator.dbm'=-63.00dbm;;;; '1#reference.signalreceive.power.dbm'=-10.00dbm;;;; '1#reference.signalreceive.quality.dbm'=-94.00db;;;;
            ...       2     --warning-snr-dbm=1.5
            ...       WARNING: Agent '1' Signal noise ratio: 2.15db | '1#signal.noise.ratio.db'=2.15dbm;0:1.5;;; '1#received.signalstrength.indicator.dbm'=-63.00dbm;;;; '1#reference.signalreceive.power.dbm'=-10.00dbm;;;; '1#reference.signalreceive.quality.dbm'=-94.00db;;;;
            ...       3     --critical-snr-dbm=2.05
            ...       CRITICAL: Agent '1' Signal noise ratio: 2.15db | '1#signal.noise.ratio.db'=2.15dbm;;0:2.05;; '1#received.signalstrength.indicator.dbm'=-63.00dbm;;;; '1#reference.signalreceive.power.dbm'=-10.00dbm;;;; '1#reference.signalreceive.quality.dbm'=-94.00db;;;;
            ...       4     --warning-rssi-dbm=-65.5
            ...       WARNING: Agent '1' Received Signal Strength Indicator: -63.00dbm | '1#signal.noise.ratio.db'=2.15dbm;;;; '1#received.signalstrength.indicator.dbm'=-63.00dbm;0:-65.5;;; '1#reference.signalreceive.power.dbm'=-10.00dbm;;;; '1#reference.signalreceive.quality.dbm'=-94.00db;;;;
            ...       5     --critical-rssi-dbm=-70.3
            ...       CRITICAL: Agent '1' Received Signal Strength Indicator: -63.00dbm | '1#signal.noise.ratio.db'=2.15dbm;;;; '1#received.signalstrength.indicator.dbm'=-63.00dbm;;0:-70.3;; '1#reference.signalreceive.power.dbm'=-10.00dbm;;;; '1#reference.signalreceive.quality.dbm'=-94.00db;;;;
            ...       6     --warning-rsrp-dbm=-15.2
            ...       WARNING: Agent '1' Reference signal receive power: -10.00dbm | '1#signal.noise.ratio.db'=2.15dbm;;;; '1#received.signalstrength.indicator.dbm'=-63.00dbm;;;; '1#reference.signalreceive.power.dbm'=-10.00dbm;0:-15.2;;; '1#reference.signalreceive.quality.dbm'=-94.00db;;;;
            ...       7     --critical-rsrp-dbm=-20.7
            ...       CRITICAL: Agent '1' Reference signal receive power: -10.00dbm | '1#signal.noise.ratio.db'=2.15dbm;;;; '1#received.signalstrength.indicator.dbm'=-63.00dbm;;;; '1#reference.signalreceive.power.dbm'=-10.00dbm;;0:-20.7;; '1#reference.signalreceive.quality.dbm'=-94.00db;;;;
            ...       8     --warning-rsrq-db=-90.5
            ...       WARNING: Agent '1' Reference signal receive quality: -94.00db | '1#signal.noise.ratio.db'=2.15dbm;;;; '1#received.signalstrength.indicator.dbm'=-63.00dbm;;;; '1#reference.signalreceive.power.dbm'=-10.00dbm;;;; '1#reference.signalreceive.quality.dbm'=-94.00db;0:-90.5;;;
            ...       9     --critical-rsrq-db=-95.2
            ...       CRITICAL: Agent '1' Reference signal receive quality: -94.00db | '1#signal.noise.ratio.db'=2.15dbm;;;; '1#received.signalstrength.indicator.dbm'=-63.00dbm;;;; '1#reference.signalreceive.power.dbm'=-10.00dbm;;;; '1#reference.signalreceive.quality.dbm'=-94.00db;;0:-95.2;;
