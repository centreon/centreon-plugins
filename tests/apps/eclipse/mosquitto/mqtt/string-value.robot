*** Settings ***
Documentation       Checks Eclipse Mosquitto MQTT plugin string-value mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown


*** Variables ***
${HOSTNAME}                 mosquitto_openssl
${MQTT_PORT}                8883
${MQTT_CA_CERTIFICATE}      /home/code/tests/robot/apps/eclipse/mosquitto/mqtt/certs/ca.crt
${MQTT_SSL_CERTIFICATE}     /home/code/tests/robot/apps/eclipse/mosquitto/mqtt/certs/client.crt
${MQTT_SSL_KEY}             /home/code/tests/robot/apps/eclipse/mosquitto/mqtt/certs/client.key

${CMD}                      ${CENTREON_PLUGINS}
...                         --plugin=apps::eclipse::mosquitto::mqtt::plugin
...                         --mode=string-value
...                         --hostname=${HOSTNAME}
...                         --mqtt-port=${MQTT_PORT}
...                         --mqtt-ca-certificate=${MQTT_CA_CERTIFICATE}
...                         --mqtt-ssl-certificate=${MQTT_SSL_CERTIFICATE}
...                         --mqtt-ssl-key=${MQTT_SSL_KEY}
...                         --mqtt-timeout=10


*** Test Cases ***
Mosquitto MQTT string-value help
    [Documentation]    Check Mosquitto MQTT string-value help
    [Tags]    eclipse    mosquitto    mqtt
    ${command}    Catenate
    ...    ${CMD}
    ...    --help

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ^Plugin Description:

Mosquitto MQTT string-value ${tc}
    [Documentation]    Check Mosquitto MQTT string-value
    [Tags]    eclipse    mosquitto    mqtt    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    --topic='${topic}'
    ...    --warning-regexp='${warning}'
    ...    --critical-regexp='${critical}'
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:   tc    topic                 warning        critical                          extraoptions                                         expected_result    --
        ...     1    $SYS/broker/version    ${EMPTY}       ${EMPTY}                          ${EMPTY}                                             ^OK: value: mosquitto version \\\\d*\.\\\\d*\.\\\\d*$
        ...     2    $SYS/broker/version    version 2.*    ${EMPTY}                          ${EMPTY}                                             ^WARNING: value: mosquitto version \\\\d*\.\\\\d*\.\\\\d*$
        ...     3    $SYS/broker/version    ${EMPTY}       version 2.*                       ${EMPTY}                                             ^CRITICAL: value: mosquitto version \\\\d*\.\\\\d*\.\\\\d*$
        ...     4    $SYS/broker/version    ${EMPTY}       MOSQUITTO.*2\.                    --regexp-insensitive                                 ^CRITICAL: value: mosquitto version \\\\d*\.\\\\d*\.\\\\d*$
        ...     5    $SYS/broker/uptime     ${EMPTY}       ^\\\\d(\\\\d{1,}\\\\sSECOND)S$    ${EMPTY}                                             ^OK: value: \\\\d* seconds$
        ...     6    $SYS/broker/uptime     ${EMPTY}       ^\\\\d(\\\\d{1,}\\\\sSECOND)S$    --regexp-insensitive                                 ^CRITICAL: value: \\\\d* seconds$
        ...     7    $SYS/broker/version    ${EMPTY}       ${EMPTY}                          --format-ok='Value \\\%{value} is ok'                ^OK: Value mosquitto version \\\\d*\.\\\\d*\.\\\\d* is ok$
        ...     8    $SYS/broker/version    version 2.*    ${EMPTY}                          --format-warning='Value \\\%{value} is a warning'    ^WARNING: Value mosquitto version \\\\d*\.\\\\d*\.\\\\d* is a warning$
        ...     9    $SYS/broker/version    ${EMPTY}       version 2.*                       --format-critical='Value \\\%{value} is critical'    ^CRITICAL: Value mosquitto version \\\\d*\.\\\\d*\.\\\\d* is critical$
