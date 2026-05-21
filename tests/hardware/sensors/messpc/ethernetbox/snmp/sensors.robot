*** Settings ***
Documentation       hardware::sensors::messpc::ethernetbox::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=hardware::sensors::messpc::ethernetbox::snmp::plugin
...         --mode=sensors
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=hardware/sensors/messpc/ethernetbox/snmp/ethernetbox


*** Test Cases ***
Sensors ${tc}
    [Tags]    hardware    sensors    snmp
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
    ...    OK: All sensors are ok | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    2
    ...    --unknown-status=1
    ...    UNKNOWN: Sensor 'Temperature' Sensor 'Temperature' status: normal, valid 1 - Sensor 'Humidity' Sensor 'Humidity' status: normal, valid 1 - Sensor 'Brightness' Sensor 'Brightness' status: normal, valid 1 - Sensor 'Contact' Sensor 'Contact' status: normal, valid 1 - Sensor 'Voltage' Sensor 'Voltage' status: normal, valid 1 - Sensor 'Smoke' Sensor 'Smoke' status: normal, valid 1 | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    3
    ...    --warning-status=1
    ...    WARNING: Sensor 'Temperature' Sensor 'Temperature' status: normal, valid 1 - Sensor 'Humidity' Sensor 'Humidity' status: normal, valid 1 - Sensor 'Brightness' Sensor 'Brightness' status: normal, valid 1 - Sensor 'Contact' Sensor 'Contact' status: normal, valid 1 - Sensor 'Voltage' Sensor 'Voltage' status: normal, valid 1 - Sensor 'Smoke' Sensor 'Smoke' status: normal, valid 1 | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    4
    ...    --critical-status=1
    ...    CRITICAL: Sensor 'Temperature' Sensor 'Temperature' status: normal, valid 1 - Sensor 'Humidity' Sensor 'Humidity' status: normal, valid 1 - Sensor 'Brightness' Sensor 'Brightness' status: normal, valid 1 - Sensor 'Contact' Sensor 'Contact' status: normal, valid 1 - Sensor 'Voltage' Sensor 'Voltage' status: normal, valid 1 - Sensor 'Smoke' Sensor 'Smoke' status: normal, valid 1 | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    5
    ...    --warning-brightness=1
    ...    WARNING: Sensor 'Brightness' brightness 75.00 % | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;0:1;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    6
    ...    --critical-brightness=1
    ...    CRITICAL: Sensor 'Brightness' brightness 75.00 % | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;0:1;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    7
    ...    --warning-contact=@1
    ...    WARNING: Sensor 'Contact' contact 1 | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;@0:1;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    8
    ...    --critical-contact=@1
    ...    CRITICAL: Sensor 'Contact' contact 1 | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;@0:1;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    9
    ...    --warning-humidity=1
    ...    WARNING: Sensor 'Humidity' humidity 45.00 % | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;0:1;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    10
    ...    --critical-humidity=1
    ...    CRITICAL: Sensor 'Humidity' humidity 45.00 % | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;0:1;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    11
    ...    --warning-smoke=@1
    ...    WARNING: Sensor 'Smoke' smoke 1 | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;@0:1;;0;1
    ...    12
    ...    --critical-smoke=@1
    ...    CRITICAL: Sensor 'Smoke' smoke 1 | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;@0:1;0;1
    ...    13
    ...    --warning-temperature=1
    ...    WARNING: Sensor 'Temperature' temperature: 22 C | 'Temperature#sensor.temperature.celsius'=22C;0:1;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    14
    ...    --critical-temperature=1
    ...    CRITICAL: Sensor 'Temperature' temperature: 22 C | 'Temperature#sensor.temperature.celsius'=22C;;0:1;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    15
    ...    --warning-voltage=1
    ...    WARNING: Sensor 'Voltage' voltage 24 V | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;0:1;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    16
    ...    --critical-voltage=1
    ...    CRITICAL: Sensor 'Voltage' voltage 24 V | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;0:1;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    17
    ...    --skip-not-valid=1
    ...    OK: All sensors are ok | 'Temperature#sensor.temperature.celsius'=22C;;;0; 'Humidity#sensor.humidity.percent'=45%;;;0;100 'Brightness#sensor.brightness.percentage'=75.00%;;;0;100 'Contact#sensor.contact'=1;;;0;1 'Voltage#sensor.voltage.volt'=24V;;;0; 'Smoke#sensor.smoke'=1;;;0;1
    ...    18
    ...    --include-sensor-type=TOTO
    ...    UNKNOWN: No sensors found
