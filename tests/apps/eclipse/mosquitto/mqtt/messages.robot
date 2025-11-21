*** Settings ***
Documentation       Checks Eclipse Mosquitto MQTT plugin messages mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
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

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ^Plugin Description:

Mosquitto MQTT messages ${tc}
    [Documentation]    Check Mosquitto MQTT messages
    [Tags]    eclipse    mosquitto    mqtt    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc   extraoptions                         expected_result    --
        ...      1     ${EMPTY}                            ^OK: Stored messages: \\\\d+, Received messages: \\\\d+, Sent messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;;\\\\d+; 'received_messages'=\\\\d+;;;\\\\d+; 'sent_messages'=\\\\d+;;;\\\\d+;$
        ...      2     --warning-messages-stored=@0:       ^WARNING: Stored messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;@0:;;\\\\d+; 'received_messages'=\\\\d+;;;\\\\d+; 'sent_messages'=\\\\d+;;;\\\\d+;$
        ...      3     --critical-messages-stored=@0:      ^CRITICAL: Stored messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;@0:;\\\\d+; 'received_messages'=\\\\d+;;;\\\\d+; 'sent_messages'=\\\\d+;;;\\\\d+;$
        ...      4     --warning-messages-received=@0:     ^WARNING: Received messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;;\\\\d+; 'received_messages'=\\\\d+;@0:;;\\\\d+; 'sent_messages'=\\\\d+;;;\\\\d+;$
        ...      5     --critical-messages-received=@0:    ^CRITICAL: Received messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;;\\\\d+; 'received_messages'=\\\\d+;;@0:;\\\\d+; 'sent_messages'=\\\\d+;;;\\\\d+;$
        ...      6     --warning-messages-sent=@0:         ^WARNING: Sent messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;;\\\\d+; 'received_messages'=\\\\d+;;;\\\\d+; 'sent_messages'=\\\\d+;@0:;;\\\\d+;$
        ...      7     --critical-messages-sent=@0:        ^CRITICAL: Sent messages: \\\\d+ \\\\| 'stored_messages'=\\\\d+;;;\\\\d+; 'received_messages'=\\\\d+;;;\\\\d+; 'sent_messages'=\\\\d+;;@0:;\\\\d+;$
