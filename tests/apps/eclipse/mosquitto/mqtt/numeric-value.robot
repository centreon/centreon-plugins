*** Settings ***
Documentation       Checks Eclipse Mosquitto MQTT plugin numeric-value mode

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
...                         --mode=numeric-value
...                         --hostname=${HOSTNAME}
...                         --mqtt-port=${MQTT_PORT}
...                         --mqtt-ca-certificate=${MQTT_CA_CERTIFICATE}
...                         --mqtt-ssl-certificate=${MQTT_SSL_CERTIFICATE}
...                         --mqtt-ssl-key=${MQTT_SSL_KEY}
...                         --mqtt-timeout=10


*** Test Cases ***
Mosquitto MQTT numeric-value help
    [Documentation]    Check Mosquitto MQTT numeric-value help
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --help

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}

Mosquitto MQTT numeric-value ${tc}
    [Documentation]    Check Mosquitto MQTT numeric-value
    [Tags]    eclipse    mosquitto    mqtt    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    --warning-uptime=${warning}
    ...    --critical-uptime=${critical}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}