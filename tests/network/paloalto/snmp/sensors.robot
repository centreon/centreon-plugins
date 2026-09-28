*** Settings ***
Documentation       network::paloalto::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...        --plugin=network::paloalto::snmp::plugin
...        --mode=sensors
...        --hostname=${HOSTNAME}
...        --snmp-port=${SNMPPORT}
...        --snmp-version=${SNMPVERSION}
...        --snmp-community=network/paloalto/snmp/paloalto

*** Test Cases ***
Sensors ${tc}
    [Tags]    network    paloalto    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All 3 components are ok [3/3 sensors]. | 'sensor.celsius_Anonymized 154'=37C;;;; 'sensor.celsius_Anonymized 224'=36C;;;; 'sensor.celsius_Anonymized 081'=41C;;;; 'count_sensor'=3;;;;
    ...    2
    ...    --component=sensor
    ...    OK: All 3 components are ok [3/3 sensors]. | 'sensor.celsius_Anonymized 154'=37C;;;; 'sensor.celsius_Anonymized 224'=36C;;;; 'sensor.celsius_Anonymized 081'=41C;;;; 'count_sensor'=3;;;;
    ...    3
    ...    --filter=sensor,2
    ...    OK: All 2 components are ok [2/2 sensors]. | 'sensor.celsius_Anonymized 224'=36C;;;; 'sensor.celsius_Anonymized 081'=41C;;;; 'count_sensor'=2;;;;
    ...    4
    ...    --filter=sensor,.* --no-component=warning
    ...    WARNING: No components are checked.
    ...    5
    ...    --warning='sensor.celsius,.*,30'
    ...    WARNING: Sensor 'Anonymized 154/2' is 37 C - Sensor 'Anonymized 224/3' is 36 C - Sensor 'Anonymized 081/4' is 41 C | 'sensor.celsius_Anonymized 154'=37C;0:30;;; 'sensor.celsius_Anonymized 224'=36C;0:30;;; 'sensor.celsius_Anonymized 081'=41C;0:30;;; 'count_sensor'=3;;;;
    ...    6
    ...    --critical='sensor.celsius,.*,40'
    ...    CRITICAL: Sensor 'Anonymized 081/4' is 41 C | 'sensor.celsius_Anonymized 154'=37C;;0:40;; 'sensor.celsius_Anonymized 224'=36C;;0:40;; 'sensor.celsius_Anonymized 081'=41C;;0:40;; 'count_sensor'=3;;;;
    ...    7
    ...    --warning-count-sensor=2
    ...    WARNING: '3' components 'sensor' checked | 'sensor.celsius_Anonymized 154'=37C;;;; 'sensor.celsius_Anonymized 224'=36C;;;; 'sensor.celsius_Anonymized 081'=41C;;;; 'count_sensor'=3;0:2;;;
    ...    8
    ...    --critical-count-sensor=2
    ...    CRITICAL: '3' components 'sensor' checked | 'sensor.celsius_Anonymized 154'=37C;;;; 'sensor.celsius_Anonymized 224'=36C;;;; 'sensor.celsius_Anonymized 081'=41C;;;; 'count_sensor'=3;;0:2;;
