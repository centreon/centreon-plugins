*** Settings ***
Documentation       Eclipse Mosquitto MQTT plugin tests

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s

Keyword Tags        notauto


*** Variables ***
${HOSTNAME}                 mosquitto_openssl
${MQTT_PORT}                8883
${MQTT_CA_CERTIFICATE}      /home/code/tests/robot/apps/eclipse/mosquitto/mqtt/certs/ca.crt
${MQTT_SSL_CERTIFICATE}     /home/code/tests/robot/apps/eclipse/mosquitto/mqtt/certs/client.crt
${MQTT_SSL_KEY}             /home/code/tests/robot/apps/eclipse/mosquitto/mqtt/certs/client.key
${CMD}                      ${CENTREON_PLUGINS} --plugin=apps::eclipse::mosquitto::mqtt::plugin --hostname=${HOSTNAME} --mqtt-port=${MQTT_PORT} --mqtt-ca-certificate=${MQTT_CA_CERTIFICATE} --mqtt-ssl-certificate=${MQTT_SSL_CERTIFICATE} --mqtt-ssl-key=${MQTT_SSL_KEY}


*** Test Cases ***
Mosquitto MQTT uptime
    [Documentation]    Check Mosquitto MQTT uptime
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=uptime
    ...    --help

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}

Mosquitto MQTT clients
    [Documentation]    Check Mosquitto MQTT uptime
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=clients
    ...    --help

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}

Mosquitto MQTT messages
    [Documentation]    Check Mosquitto MQTT uptime
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=messages
    ...    --help

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}

Mosquitto MQTT numeric-value
    [Documentation]    Check Mosquitto MQTT uptime
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=numeric-value
    ...    --help

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}

Mosquitto MQTT string-value
    [Documentation]    Check Mosquitto MQTT uptime
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=string-value
    ...    --help

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
