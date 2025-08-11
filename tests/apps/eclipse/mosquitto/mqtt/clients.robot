*** Settings ***
Documentation       Eclipse Mosquitto MQTT plugin clients mode

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

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ^Plugin Description:

Mosquitto MQTT clients ${tc}
    [Documentation]    Check Mosquitto MQTT clients
    [Tags]    eclipse    mosquitto    mqtt    notauto
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}    ${tc}

    Examples:    tc    extraoptions                       expected_result    --
        ...      1     ${EMPTY}                           ^OK: Connected clients: \\\\d+, Maximum clients: \\\\d+, Active clients: \\\\d+, Inactive clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      2     --warning-clients-connected=@0     ^WARNING: Connected clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;@0:0;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      3     --critical-clients-connected=@0    ^CRITICAL: Connected clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;@0:0;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      4     --warning-clients-maximum=0        ^WARNING: Maximum clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;0:0;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      5     --critical-clients-maximum=0       ^CRITICAL: Maximum clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;0:0;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      6     --warning-clients-active=@0:1      ^WARNING: Active clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;@0:1;;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      7     --critical-clients-active=@0:1     ^CRITICAL: Active clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;@0:1;\\\\d+; 'inactive_clients'=\\\\d+;;;\\\\d+;$
        ...      8     --warning-clients-inactive=@0      ^WARNING: Inactive clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;@0:0;;\\\\d+;$
        ...      9     --critical-clients-inactive=@0      ^CRITICAL: Inactive clients: \\\\d+ \\\\| 'connected_clients'=\\\\d+;;;\\\\d+; 'maximum_clients'=\\\\d+;;;\\\\d+; 'active_clients'=\\\\d+;;;\\\\d+; 'inactive_clients'=\\\\d+;;@0:0;\\\\d+;$

