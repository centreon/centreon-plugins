*** Settings ***
Documentation       network::aviat::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::aviat::snmp::plugin
...         --mode=sensors
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/aviat/snmp/aviat


*** Test Cases ***
Sensors ${tc}
    [Tags]    network    aviat    snmp
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
    ...    OK: All 30 components are ok [10/10 power, 5/5 temperature, 15/15 voltage]. | 'BBC ANOAAZZAZZ9~RSL#sensor.power.dBm'=-33.6dBm;;;; 'BBC ANOAAZZAZZ9~SNR#sensor.power.dB'=45.7dB;;;; 'BBC ANOAAZZAZZ9~ATPC Fade Margin#sensor.power.dB'=50dB;;;; 'BBC ANOAAZZAZZ9~Cross Pole Discrimination#sensor.power.dB'=0dB;;;; 'BBC ANOAAZZAZZ9~Remote RSL#sensor.power.dBm'=-34.5dBm;;;; 'BBC ANOAAZZAZZ9~Remote SNR#sensor.power.dB'=46dB;;;; 'BBC ANOAAZZAZZ9~Forward Power#sensor.power.dBm'=10dBm;;;; 'BBC ANOAAZZAZZ9~RSL at ACU/OBU Antenna Port#sensor.power.dBm'=0dBm;;;; 'BBC ANOAAZZAZZ9~Tx Power at ACU/OBU Antenna Port#sensor.power.dBm'=0dBm;;;; 'BBC ANOAAZZAZZ9~ATPC Tx Power#sensor.power.dBm'=10dBm;;;; 'BBC ANOAAZZAZZ9~Pwr Det Temperature#sensor.temperature.celsius'=41C;;;; 'BBC ANOAAZZAZZ9~Max Temperature#sensor.temperature.celsius'=0C;;;; 'BBC ANOAAZZAZZ9~Min Temperature#sensor.temperature.celsius'=0C;;;; 'BBC ANOAAZZAZZ9~IF Temperature#sensor.temperature.celsius'=41C;;;; 'BBC ANOAAZZAZZ9~Rx Temperature#sensor.temperature.celsius'=41C;;;; 'BBC ANOAAZZAZZ9~Cable AGC#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~RSSI Voltage#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~RAC -5V digital supply#sensor.voltage.volt'=-4.95V;;;; 'BBC ANOAAZZAZZ9~RAC +5V digital supply#sensor.voltage.volt'=5V;;;; 'BBC ANOAAZZAZZ9~RAC +2.5V digital supply#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~RAC +3.3V digital supply#sensor.voltage.volt'=3.32V;;;; 'BBC ANOAAZZAZZ9~RAC -48V supply#sensor.voltage.volt'=-54.03V;;;; 'BBC ANOAAZZAZZ9~RAC TX IF Level#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~RAC RX AGC Level#sensor.voltage.volt'=0.89V;;;; 'BBC ANOAAZZAZZ9~TX IF Level#sensor.voltage.volt'=0.18V;;;; 'BBC ANOAAZZAZZ9~RAC +1.8V digital supply#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~RAC +1.2V supply#sensor.voltage.volt'=1.22V;;;; 'BBC ANOAAZZAZZ9~ODU -48V supply#sensor.voltage.volt'=-54.1V;;;; 'BBC ANOAAZZAZZ9~IF 1 AGC#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~IF 2 AGC#sensor.voltage.volt'=0V;;;; 'hardware.power.count'=10;;;; 'hardware.temperature.count'=5;;;; 'hardware.voltage.count'=15;;;;
    ...    2
    ...    --component=power
    ...    OK: All 10 components are ok [10/10 power]. | 'BBC ANOAAZZAZZ9~RSL#sensor.power.dBm'=-33.6dBm;;;; 'BBC ANOAAZZAZZ9~SNR#sensor.power.dB'=45.7dB;;;; 'BBC ANOAAZZAZZ9~ATPC Fade Margin#sensor.power.dB'=50dB;;;; 'BBC ANOAAZZAZZ9~Cross Pole Discrimination#sensor.power.dB'=0dB;;;; 'BBC ANOAAZZAZZ9~Remote RSL#sensor.power.dBm'=-34.5dBm;;;; 'BBC ANOAAZZAZZ9~Remote SNR#sensor.power.dB'=46dB;;;; 'BBC ANOAAZZAZZ9~Forward Power#sensor.power.dBm'=10dBm;;;; 'BBC ANOAAZZAZZ9~RSL at ACU/OBU Antenna Port#sensor.power.dBm'=0dBm;;;; 'BBC ANOAAZZAZZ9~Tx Power at ACU/OBU Antenna Port#sensor.power.dBm'=0dBm;;;; 'BBC ANOAAZZAZZ9~ATPC Tx Power#sensor.power.dBm'=10dBm;;;; 'hardware.power.count'=10;;;;
    ...    3
    ...    --filter=power,1
    ...    OK: All 27 components are ok [7/7 power, 5/5 temperature, 15/15 voltage]. | 'BBC ANOAAZZAZZ9~Cross Pole Discrimination#sensor.power.dB'=0dB;;;; 'BBC ANOAAZZAZZ9~Remote RSL#sensor.power.dBm'=-34.5dBm;;;; 'BBC ANOAAZZAZZ9~Remote SNR#sensor.power.dB'=46dB;;;; 'BBC ANOAAZZAZZ9~Forward Power#sensor.power.dBm'=10dBm;;;; 'BBC ANOAAZZAZZ9~RSL at ACU/OBU Antenna Port#sensor.power.dBm'=0dBm;;;; 'BBC ANOAAZZAZZ9~Tx Power at ACU/OBU Antenna Port#sensor.power.dBm'=0dBm;;;; 'BBC ANOAAZZAZZ9~ATPC Tx Power#sensor.power.dBm'=10dBm;;;; 'BBC ANOAAZZAZZ9~Pwr Det Temperature#sensor.temperature.celsius'=41C;;;; 'BBC ANOAAZZAZZ9~Max Temperature#sensor.temperature.celsius'=0C;;;; 'BBC ANOAAZZAZZ9~Min Temperature#sensor.temperature.celsius'=0C;;;; 'BBC ANOAAZZAZZ9~IF Temperature#sensor.temperature.celsius'=41C;;;; 'BBC ANOAAZZAZZ9~Rx Temperature#sensor.temperature.celsius'=41C;;;; 'BBC ANOAAZZAZZ9~Cable AGC#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~RSSI Voltage#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~RAC -5V digital supply#sensor.voltage.volt'=-4.95V;;;; 'BBC ANOAAZZAZZ9~RAC +5V digital supply#sensor.voltage.volt'=5V;;;; 'BBC ANOAAZZAZZ9~RAC +2.5V digital supply#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~RAC +3.3V digital supply#sensor.voltage.volt'=3.32V;;;; 'BBC ANOAAZZAZZ9~RAC -48V supply#sensor.voltage.volt'=-54.03V;;;; 'BBC ANOAAZZAZZ9~RAC TX IF Level#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~RAC RX AGC Level#sensor.voltage.volt'=0.89V;;;; 'BBC ANOAAZZAZZ9~TX IF Level#sensor.voltage.volt'=0.18V;;;; 'BBC ANOAAZZAZZ9~RAC +1.8V digital supply#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~RAC +1.2V supply#sensor.voltage.volt'=1.22V;;;; 'BBC ANOAAZZAZZ9~ODU -48V supply#sensor.voltage.volt'=-54.1V;;;; 'BBC ANOAAZZAZZ9~IF 1 AGC#sensor.voltage.volt'=0V;;;; 'BBC ANOAAZZAZZ9~IF 2 AGC#sensor.voltage.volt'=0V;;;; 'hardware.power.count'=7;;;; 'hardware.temperature.count'=5;;;; 'hardware.voltage.count'=15;;;;
    ...    4
    ...    --component=voltage --filter=voltage --no-component=ok
    ...    OK: All 0 components are ok []. - No components are checked.
    ...    5
    ...    --component=temperature --warning='temperature,.*,30'
    ...    WARNING: Sensor temperature 'Pwr Det Temperature' is 41 C [slot: BBC ANOAAZZAZZ9] - Sensor temperature 'IF Temperature' is 41 C [slot: BBC ANOAAZZAZZ9] - Sensor temperature 'Rx Temperature' is 41 C [slot: BBC ANOAAZZAZZ9] | 'BBC ANOAAZZAZZ9~Pwr Det Temperature#sensor.temperature.celsius'=41C;0:30;;; 'BBC ANOAAZZAZZ9~Max Temperature#sensor.temperature.celsius'=0C;0:30;;; 'BBC ANOAAZZAZZ9~Min Temperature#sensor.temperature.celsius'=0C;0:30;;; 'BBC ANOAAZZAZZ9~IF Temperature#sensor.temperature.celsius'=41C;0:30;;; 'BBC ANOAAZZAZZ9~Rx Temperature#sensor.temperature.celsius'=41C;0:30;;; 'hardware.temperature.count'=5;;;;
    ...    6
    ...    --component=temperature --critical='temperature,.*,30'
    ...    CRITICAL: Sensor temperature 'Pwr Det Temperature' is 41 C [slot: BBC ANOAAZZAZZ9] - Sensor temperature 'IF Temperature' is 41 C [slot: BBC ANOAAZZAZZ9] - Sensor temperature 'Rx Temperature' is 41 C [slot: BBC ANOAAZZAZZ9] | 'BBC ANOAAZZAZZ9~Pwr Det Temperature#sensor.temperature.celsius'=41C;;0:30;; 'BBC ANOAAZZAZZ9~Max Temperature#sensor.temperature.celsius'=0C;;0:30;; 'BBC ANOAAZZAZZ9~Min Temperature#sensor.temperature.celsius'=0C;;0:30;; 'BBC ANOAAZZAZZ9~IF Temperature#sensor.temperature.celsius'=41C;;0:30;; 'BBC ANOAAZZAZZ9~Rx Temperature#sensor.temperature.celsius'=41C;;0:30;; 'hardware.temperature.count'=5;;;;
