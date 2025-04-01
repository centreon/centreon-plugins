*** Settings ***
Documentation       Eclipse Mosquitto MQTT plugin clients mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${HOSTNAME}                 mosquitto_openssl
${MQTT_PORT}                8883
${MQTT_CA_CERTIFICATE}      /home/code/tests/robot/apps/eclipse/mosquitto/mqtt/certs/ca.crt
${MQTT_SSL_CERTIFICATE}     /home/code/tests/robot/apps/eclipse/mosquitto/mqtt/certs/client.crt
${MQTT_SSL_KEY}             /home/code/tests/robot/apps/eclipse/mosquitto/mqtt/certs/client.key

${CMD}                      ${CENTREON_PLUGINS}
...                         --plugin=apps::eclipse::mosquitto::mqtt::plugin
...                         --mode=clients
...                         --hostname=${HOSTNAME}
...                         --mqtt-port=${MQTT_PORT}
...                         --mqtt-ca-certificate=${MQTT_CA_CERTIFICATE}
...                         --mqtt-ssl-certificate=${MQTT_SSL_CERTIFICATE}
...                         --mqtt-ssl-key=${MQTT_SSL_KEY}
...                         --mqtt-timeout=10


*** Test Cases ***
Mosquitto MQTT clients help
    [Documentation]    Check Mosquitto MQTT clients help
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --help

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}

Mosquitto MQTT clients ${tc}
    [Documentation]    Check Mosquitto MQTT clients
    [Tags]    eclipse    mosquitto    mqtt    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    --warning-clients-connected=${warning-connected}
    ...    --critical-clients-connected=${critical-connected}
    ...    --warning-clients-maximum=${warning-maximum}
    ...    --critical-clients-maximum=${critical-maximum}
    ...    --warning-clients-active=${warning-active}
    ...    --critical-clients-active=${critical-active}
    ...    --warning-clients-inactive=${warning-inactive}
    ...    --critical-clients-inactive=${critical-inactive}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    warning-connected     critical-connected    warning-maximum    critical-maximum    warning-active    critical-active    warning-inactive    critical-inactive    expected_result    --
        ...      1     ${EMPTY}              ${EMPTY}              ${EMPTY}           ${EMPTY}            ${EMPTY}          ${EMPTY}           ${EMPTY}            ${EMPTY}             ^OK: Connected clients: \\\\d+, Maximum clients: \\\\d+, Active clients: \\\\d+, Inactive clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      2     @0                    ${EMPTY}              ${EMPTY}           ${EMPTY}            ${EMPTY}          ${EMPTY}           ${EMPTY}            ${EMPTY}             ^WARNING: Connected clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;@0:0;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      3     ${EMPTY}              @0                    ${EMPTY}           ${EMPTY}            ${EMPTY}          ${EMPTY}           ${EMPTY}            ${EMPTY}             ^CRITICAL: Connected clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;@0:0;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      4     ${EMPTY}              ${EMPTY}              0                  ${EMPTY}            ${EMPTY}          ${EMPTY}           ${EMPTY}            ${EMPTY}             ^WARNING: Maximum clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;0:0;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      5     ${EMPTY}              ${EMPTY}              ${EMPTY}           0                   ${EMPTY}          ${EMPTY}           ${EMPTY}            ${EMPTY}             ^CRITICAL: Maximum clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;0:0;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      6     ${EMPTY}              ${EMPTY}              ${EMPTY}           ${EMPTY}            @0:1              ${EMPTY}           ${EMPTY}            ${EMPTY}             ^WARNING: Active clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;@0:1;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      7     ${EMPTY}              ${EMPTY}              ${EMPTY}           ${EMPTY}            ${EMPTY}          @0:1               ${EMPTY}            ${EMPTY}             ^CRITICAL: Active clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;@0:1;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      8     ${EMPTY}              ${EMPTY}              ${EMPTY}           ${EMPTY}            ${EMPTY}          ${EMPTY}           @0                  ${EMPTY}             ^WARNING: Inactive clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;@0:0;;\\\\d+;$
        ...      9     ${EMPTY}              ${EMPTY}              ${EMPTY}           ${EMPTY}            ${EMPTY}          ${EMPTY}           ${EMPTY}            @0                   ^CRITICAL: Inactive clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;@0:0;\\\\d+;$
