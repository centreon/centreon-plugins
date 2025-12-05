*** Settings ***
Documentation       snmp_standard
Resource            ${CURDIR}${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --mode=sensors
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}

*** Test Cases ***
Mellanox-Sensors ${tc}
    [Tags]    network    mellanox    snmp    snmp_standard
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=network::mellanox::snmp::plugin
    ...    --snmp-community=snmp_standard/network-mellanox
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extra_options                        expected_result    --
            ...     1    ${EMPTY}                             OK: All 22 components are ok [22/22 sensors]. | 'sensor.watts_Power Sensor'=60W;;;; 'sensor.amperes_Current Sensor'=5040A;;;; 'sensor.voltsAC_Voltage Sensor'=12V;;;; 'sensor.watts_Power Sensor'=0W;;;; 'sensor.amperes_Current Sensor'=0A;;;; 'sensor.voltsAC_Voltage Sensor'=0V;;;; 'sensor.rpm_Fan Sensor'=11606rpm;;;; 'sensor.rpm_Fan Sensor'=12250rpm;;;; 'sensor.rpm_Fan Sensor'=12720rpm;;;; 'sensor.rpm_Fan Sensor'=11505rpm;;;; 'sensor.celsius_Temperature Sensor'=21C;;;; 'sensor.celsius_Temperature Sensor'=21C;;;; 'sensor.celsius_Temperature Sensor'=21C;;;; 'sensor.celsius_Temperature Sensor'=22C;;;; 'sensor.celsius_Temperature Sensor'=27.5C;;;; 'sensor.celsius_Temperature Sensor'=28.5C;;;; 'sensor.watts_Power Sensor'=63W;;;; 'sensor.amperes_Current Sensor'=5280A;;;; 'sensor.voltsDC_Voltage Sensor'=12V;;;; 'sensor.celsius_Temperature Sensor'=46C;;;; 'sensor.watts_Power Sensor'=0.6123W;;;; 'sensor.watts_Power Sensor'=0.5917W;;;; 'count_sensor'=22;;;;
            ...     2    --warning='sensor.celsius,.*,30'     WARNING: Sensor 'Temperature Sensor/200370011' is 46 C | 'sensor.watts_Power Sensor'=60W;;;; 'sensor.amperes_Current Sensor'=5040A;;;; 'sensor.voltsAC_Voltage Sensor'=12V;;;; 'sensor.watts_Power Sensor'=0W;;;; 'sensor.amperes_Current Sensor'=0A;;;; 'sensor.voltsAC_Voltage Sensor'=0V;;;; 'sensor.rpm_Fan Sensor'=11606rpm;;;; 'sensor.rpm_Fan Sensor'=12250rpm;;;; 'sensor.rpm_Fan Sensor'=12720rpm;;;; 'sensor.rpm_Fan Sensor'=11505rpm;;;; 'sensor.celsius_Temperature Sensor'=21C;0:30;;; 'sensor.celsius_Temperature Sensor'=21C;0:30;;; 'sensor.celsius_Temperature Sensor'=21C;0:30;;; 'sensor.celsius_Temperature Sensor'=22C;0:30;;; 'sensor.celsius_Temperature Sensor'=27.5C;0:30;;; 'sensor.celsius_Temperature Sensor'=28.5C;0:30;;; 'sensor.watts_Power Sensor'=63W;;;; 'sensor.amperes_Current Sensor'=5280A;;;; 'sensor.voltsDC_Voltage Sensor'=12V;;;; 'sensor.celsius_Temperature Sensor'=46C;0:30;;; 'sensor.watts_Power Sensor'=0.6123W;;;; 'sensor.watts_Power Sensor'=0.5917W;;;; 'count_sensor'=22;;;;
            ...     3    --critical='sensor.celsius,.*,30'    CRITICAL: Sensor 'Temperature Sensor/200370011' is 46 C | 'sensor.watts_Power Sensor'=60W;;;; 'sensor.amperes_Current Sensor'=5040A;;;; 'sensor.voltsAC_Voltage Sensor'=12V;;;; 'sensor.watts_Power Sensor'=0W;;;; 'sensor.amperes_Current Sensor'=0A;;;; 'sensor.voltsAC_Voltage Sensor'=0V;;;; 'sensor.rpm_Fan Sensor'=11606rpm;;;; 'sensor.rpm_Fan Sensor'=12250rpm;;;; 'sensor.rpm_Fan Sensor'=12720rpm;;;; 'sensor.rpm_Fan Sensor'=11505rpm;;;; 'sensor.celsius_Temperature Sensor'=21C;;0:30;; 'sensor.celsius_Temperature Sensor'=21C;;0:30;; 'sensor.celsius_Temperature Sensor'=21C;;0:30;; 'sensor.celsius_Temperature Sensor'=22C;;0:30;; 'sensor.celsius_Temperature Sensor'=27.5C;;0:30;; 'sensor.celsius_Temperature Sensor'=28.5C;;0:30;; 'sensor.watts_Power Sensor'=63W;;;; 'sensor.amperes_Current Sensor'=5280A;;;; 'sensor.voltsDC_Voltage Sensor'=12V;;;; 'sensor.celsius_Temperature Sensor'=46C;;0:30;; 'sensor.watts_Power Sensor'=0.6123W;;;; 'sensor.watts_Power Sensor'=0.5917W;;;; 'count_sensor'=22;;;;
            ...     4    --warning-count-sensor=1             WARNING: '22' components 'sensor' checked | 'sensor.watts_Power Sensor'=60W;;;; 'sensor.amperes_Current Sensor'=5040A;;;; 'sensor.voltsAC_Voltage Sensor'=12V;;;; 'sensor.watts_Power Sensor'=0W;;;; 'sensor.amperes_Current Sensor'=0A;;;; 'sensor.voltsAC_Voltage Sensor'=0V;;;; 'sensor.rpm_Fan Sensor'=11606rpm;;;; 'sensor.rpm_Fan Sensor'=12250rpm;;;; 'sensor.rpm_Fan Sensor'=12720rpm;;;; 'sensor.rpm_Fan Sensor'=11505rpm;;;; 'sensor.celsius_Temperature Sensor'=21C;;;; 'sensor.celsius_Temperature Sensor'=21C;;;; 'sensor.celsius_Temperature Sensor'=21C;;;; 'sensor.celsius_Temperature Sensor'=22C;;;; 'sensor.celsius_Temperature Sensor'=27.5C;;;; 'sensor.celsius_Temperature Sensor'=28.5C;;;; 'sensor.watts_Power Sensor'=63W;;;; 'sensor.amperes_Current Sensor'=5280A;;;; 'sensor.voltsDC_Voltage Sensor'=12V;;;; 'sensor.celsius_Temperature Sensor'=46C;;;; 'sensor.watts_Power Sensor'=0.6123W;;;; 'sensor.watts_Power Sensor'=0.5917W;;;; 'count_sensor'=22;0:1;;;
            ...     5    --critical-count-sensor=1            CRITICAL: '22' components 'sensor' checked | 'sensor.watts_Power Sensor'=60W;;;; 'sensor.amperes_Current Sensor'=5040A;;;; 'sensor.voltsAC_Voltage Sensor'=12V;;;; 'sensor.watts_Power Sensor'=0W;;;; 'sensor.amperes_Current Sensor'=0A;;;; 'sensor.voltsAC_Voltage Sensor'=0V;;;; 'sensor.rpm_Fan Sensor'=11606rpm;;;; 'sensor.rpm_Fan Sensor'=12250rpm;;;; 'sensor.rpm_Fan Sensor'=12720rpm;;;; 'sensor.rpm_Fan Sensor'=11505rpm;;;; 'sensor.celsius_Temperature Sensor'=21C;;;; 'sensor.celsius_Temperature Sensor'=21C;;;; 'sensor.celsius_Temperature Sensor'=21C;;;; 'sensor.celsius_Temperature Sensor'=22C;;;; 'sensor.celsius_Temperature Sensor'=27.5C;;;; 'sensor.celsius_Temperature Sensor'=28.5C;;;; 'sensor.watts_Power Sensor'=63W;;;; 'sensor.amperes_Current Sensor'=5280A;;;; 'sensor.voltsDC_Voltage Sensor'=12V;;;; 'sensor.celsius_Temperature Sensor'=46C;;;; 'sensor.watts_Power Sensor'=0.6123W;;;; 'sensor.watts_Power Sensor'=0.5917W;;;; 'count_sensor'=22;;0:1;;
