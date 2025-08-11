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

    Ctn Run Command And Check Result As Regexp    ${command}    ^Plugin Description:    ${tc}

Mosquitto MQTT numeric-value ${tc}
    [Documentation]    Check Mosquitto MQTT numeric-value
    [Tags]    eclipse    mosquitto    mqtt    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    --topic='${topic}'
    ...    --warning=${warning}
    ...    --critical=${critical}
    ...    --extracted-pattern='${extracted_pattern}'
    ...    --format='${format}'
    ...    --format-custom='${format_custom}'
    ...    --perfdata-unit=${perfdata_unit}
    ...    --perfdata-name=${perfdata_name}
    ...    --perfdata-min=${perfdata_min}
    ...    --perfdata-max=${perfdata_max}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}    ${tc}

    Examples:    tc    topic                         warning     critical    extracted_pattern     format                         format_custom    perfdata_unit    perfdata_name     perfdata_min    perfdata_max    expected_result    --
        ...      1     $SYS/broker/messages/sent     ${EMPTY}    ${EMPTY}    ${EMPTY}              current value is %s            ${EMPTY}         ${EMPTY}         value             ${EMPTY}        ${EMPTY}        ^OK: current value is \\\\d* \\\\| 'value'=\\\\d*;;;;$
        ...      2     $SYS/broker/uptime            ${EMPTY}    ${EMPTY}    ^(\\\\d+) seconds$    current uptime is %ss          ${EMPTY}         s                uptime            ${EMPTY}        ${EMPTY}        ^OK: current uptime is \\\\d*s \\\\| 'uptime'=\\\\d*s;;;;$
        ...      3     $SYS/broker/uptime            ${EMPTY}    ${EMPTY}    ^(\\\\d+) seconds$    current uptime is %sm          / 60             m                uptime            ${EMPTY}        ${EMPTY}        ^OK: current uptime is \\\\d*(\\\\.\\\\d*)?m \\\\| 'uptime'=\\\\d*(\\\\.\\\\d*)?m;;;;$
        ...      4     $SYS/broker/clients/total     ${EMPTY}    ${EMPTY}    ${EMPTY}              there are %s total clients     + 2 / 2          ${EMPTY}         clients.total     0               2               ^OK: there are \\\\d* total clients \\\\| 'clients.total'=\\\\d*;;;0;2$
        ...      5     $SYS/broker/clients/active    1           ${EMPTY}    ${EMPTY}              there are %s active clients    + 2              ${EMPTY}         clients.active    0               3               ^WARNING: there are \\\\d* active clients \\\\| 'clients.active'=\\\\d*;0:1;;0;3$
        ...      6     $SYS/broker/clients/active    ${EMPTY}    1           ${EMPTY}              there are %s active clients    + 2              ${EMPTY}         clients.active    0               3               ^CRITICAL: there are \\\\d* active clients \\\\| 'clients.active'=\\\\d*;;0:1;0;3$
