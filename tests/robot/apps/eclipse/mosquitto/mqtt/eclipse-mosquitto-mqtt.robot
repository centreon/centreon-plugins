*** Settings ***
Documentation       Eclipse Mosquitto MQTT plugin tests

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s

Keyword Tags    notauto


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
    ...    --mqtt-timeout=${timeout}
    ...    --warning-uptime=${warning}
    ...    --critical-uptime=${critical}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Match Regexp
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:    tc    timeout    warning     critical    expected_result    --
        ...      1     10         ${EMPTY}    ${EMPTY}    OK: uptime is:( \d+d)?( \d+h)?( \d+m)?( \d+s)? \| 'uptime'=\d+s;;\d+:\d+;\d+;
        ...      2     10         1           ${EMPTY}    WARNING: uptime is:( \d+d)?( \d+h)?( \d+m)?( \d+s)? \| 'uptime'=\d+s;;\d+:\d+;\d+;
        ...      3     10         ${EMPTY}    1           CRITICAL: uptime is:( \d+d)?( \d+h)?( \d+m)?( \d+s)? \| 'uptime'=\d+s;;\d+:\d+;\d+;

Mosquitto MQTT clients
    [Documentation]    Check Mosquitto MQTT clients
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=clients
    ...    --mqtt-timeout=${timeout}
    ...    --warning-clients-connected=${warning-connected}
    ...    --critical-clients-connected=${critical-connected}
    ...    --warning-clients-maximum=${warning-maximum}
    ...    --critical-clients-maximum=${critical-maximum}
    ...    --warning-clients-active=${warning-active}
    ...    --critical-clients-active=${critical-active}
    ...    --warning-clients-inactive=${warning-inactive}
    ...    --critical-clients-inactive=${critical-inactive}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Match Regexp
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:    tc    timeout    warning-connected     critical-connected    warning-maximum    critical-maximum    warning-active    critical-active    warning-inactive    critical-inactive    expected_result    --
        ...      1     10         ${EMPTY}    ${EMPTY}    ${EMPTY}    ${EMPTY}    ${EMPTY}    ${EMPTY}    ${EMPTY}    ${EMPTY}    OK: Connected clients: 0, Maximum clients: 1, Active clients: 0, Inactive clients: 0 | 'connected_clients'=0;;;0; 'maximum_clients'=1;;;0; 'active_clients'=0;;;0; 'inactive_clients'=0;;;0;
