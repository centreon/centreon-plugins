*** Settings ***
Documentation       Checks Eclipse Mosquitto MQTT plugin uptime mode

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
...                         --mode=uptime
...                         --hostname=${HOSTNAME}
...                         --mqtt-port=${MQTT_PORT}
...                         --mqtt-ca-certificate=${MQTT_CA_CERTIFICATE}
...                         --mqtt-ssl-certificate=${MQTT_SSL_CERTIFICATE}
...                         --mqtt-ssl-key=${MQTT_SSL_KEY}
...                         --mqtt-timeout=10


*** Test Cases ***
Mosquitto MQTT uptime help
    [Documentation]    Check Mosquitto MQTT uptime help
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --help

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}

Mosquitto MQTT uptime ${tc}
    [Documentation]    Check Mosquitto MQTT uptime
    [Tags]    eclipse    mosquitto    mqtt    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    --warning-uptime=${warning}
    ...    --critical-uptime=${critical}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    warning     critical    expected_result    --
        ...      1     ${EMPTY}    ${EMPTY}    ^OK: uptime is:( \\\\d+d)?( \\\\d+h)?( \\\\d+m)?( \\\\d+s)? \\\\| 'uptime'=\\\\d+s;;;\\\\d+;$
        ...      2     1           ${EMPTY}    ^WARNING: uptime is:( \\\\d+d)?( \\\\d+h)?( \\\\d+m)?( \\\\d+s)? \\\\| 'uptime'=\\\\d+s;0:1;;\\\\d+;$
        ...      3     ${EMPTY}    1           ^CRITICAL: uptime is:( \\\\d+d)?( \\\\d+h)?( \\\\d+m)?( \\\\d+s)? \\\\| 'uptime'=\\\\d+s;;0:1;\\\\d+;$
