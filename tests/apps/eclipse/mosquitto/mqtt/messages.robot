*** Settings ***
Documentation       Checks Eclipse Mosquitto MQTT plugin messages mode

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
...                         --mode=messages
...                         --hostname=${HOSTNAME}
...                         --mqtt-port=${MQTT_PORT}
...                         --mqtt-ca-certificate=${MQTT_CA_CERTIFICATE}
...                         --mqtt-ssl-certificate=${MQTT_SSL_CERTIFICATE}
...                         --mqtt-ssl-key=${MQTT_SSL_KEY}
...                         --mqtt-timeout=10


*** Test Cases ***
Mosquitto MQTT messages help
    [Documentation]    Check Mosquitto MQTT messages help
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --help

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}

Mosquitto MQTT messages ${tc}
    [Documentation]    Check Mosquitto MQTT messages
    [Tags]    eclipse    mosquitto    mqtt    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    --warning-messages-stored=${warning-stored}
    ...    --critical-messages-stored=${critical-stored}
    ...    --warning-messages-received=${warning-received}
    ...    --critical-messages-received=${critical-received}
    ...    --warning-messages-sent=${warning-sent}
    ...    --critical-messages-sent=${critical-sent}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    warning-stored     critical-stored    warning-received    critical-received    warning-sent    critical-sent    expected_result    --
        ...      1     ${EMPTY}           ${EMPTY}           ${EMPTY}            ${EMPTY}             ${EMPTY}        ${EMPTY}         ^OK: Stored messages: \\\\d+, Received messages: \\\\d+, Sent messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;;\\\\d+; 'received_messages'=\\\\d+;;;\\\\d+; 'sent_messages'=\\\\d+;;;\\\\d+;$
        ...      2     @0:                ${EMPTY}           ${EMPTY}            ${EMPTY}             ${EMPTY}        ${EMPTY}         ^WARNING: Stored messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;@0:;;\\\\d+; 'received_messages'=\\\\d+;;;\\\\d+; 'sent_messages'=\\\\d+;;;\\\\d+;$
        ...      3     ${EMPTY}           @0:                ${EMPTY}            ${EMPTY}             ${EMPTY}        ${EMPTY}         ^CRITICAL: Stored messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;@0:;\\\\d+; 'received_messages'=\\\\d+;;;\\\\d+; 'sent_messages'=\\\\d+;;;\\\\d+;$
        ...      4     ${EMPTY}           ${EMPTY}           @0:                 ${EMPTY}             ${EMPTY}        ${EMPTY}         ^WARNING: Received messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;;\\\\d+; 'received_messages'=\\\\d+;@0:;;\\\\d+; 'sent_messages'=\\\\d+;;;\\\\d+;$
        ...      5     ${EMPTY}           ${EMPTY}           ${EMPTY}            @0:                  ${EMPTY}        ${EMPTY}         ^CRITICAL: Received messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;;\\\\d+; 'received_messages'=\\\\d+;;@0:;\\\\d+; 'sent_messages'=\\\\d+;;;\\\\d+;$
        ...      6     ${EMPTY}           ${EMPTY}           ${EMPTY}            ${EMPTY}             @0:             ${EMPTY}         ^WARNING: Sent messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;;\\\\d+; 'received_messages'=\\\\d+;;;\\\\d+; 'sent_messages'=\\\\d+;@0:;;\\\\d+;$
        ...      7     ${EMPTY}           ${EMPTY}           ${EMPTY}            ${EMPTY}             ${EMPTY}        @0:              ^CRITICAL: Sent messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;;\\\\d+; 'received_messages'=\\\\d+;;;\\\\d+; 'sent_messages'=\\\\d+;;@0:;\\\\d+;$
