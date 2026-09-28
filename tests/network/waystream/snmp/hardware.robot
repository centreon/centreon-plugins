*** Settings ***
Documentation       network::waystream::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::waystream::snmp::plugin
...         --mode=hardware
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}


*** Test Cases ***
Hardware MS4000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms4000
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All 15 components are ok [3/3 fans, 3/3 temperatures, 9/9 voltages]. | 'fan_1'=7219rpm;;;; 'fan_2'=6923rpm;;;; 'fan_3'=7219rpm;;;; 'temperature_0'=42.75C;;0:60;; 'temperature_1'=36.00C;;0:60;; 'temperature_2'=40.00C;;0:60;; 'voltage_0'=1.00V;;0.85:1.15;; 'voltage_1'=0.99V;;0.85:1.15;; 'voltage_2'=4.90V;;4.25:5.75;; 'voltage_3'=1.79V;;1.53:2.07;; 'voltage_4'=3.38V;;2.805:3.794;; 'voltage_5'=12.06V;;10.2:13.799;; 'voltage_6'=4.94V;;4.25:5.75;; 'voltage_7'=4.91V;;4.25:5.75;; 'voltage_8'=3.30V;;2.55:3.449;; 'count_fan'=3;;;; 'count_temperature'=3;;;; 'count_voltage'=9;;;;
    ...    2
    ...    --component=fan
    ...    OK: All 3 components are ok [3/3 fans]. | 'fan_1'=7219rpm;;;; 'fan_2'=6923rpm;;;; 'fan_3'=7219rpm;;;; 'count_fan'=3;;;;
    ...    3
    ...    --filter=voltage
    ...    OK: All 6 components are ok [3/3 fans, 3/3 temperatures]. | 'fan_1'=7219rpm;;;; 'fan_2'=6923rpm;;;; 'fan_3'=7219rpm;;;; 'temperature_0'=42.75C;;0:60;; 'temperature_1'=36.00C;;0:60;; 'temperature_2'=40.00C;;0:60;; 'count_fan'=3;;;; 'count_temperature'=3;;;;
    ...    5
    ...    --no-component=critical
    ...    OK: All 15 components are ok [3/3 fans, 3/3 temperatures, 9/9 voltages]. | 'fan_1'=7219rpm;;;; 'fan_2'=6923rpm;;;; 'fan_3'=7219rpm;;;; 'temperature_0'=42.75C;;0:60;; 'temperature_1'=36.00C;;0:60;; 'temperature_2'=40.00C;;0:60;; 'voltage_0'=1.00V;;0.85:1.15;; 'voltage_1'=0.99V;;0.85:1.15;; 'voltage_2'=4.90V;;4.25:5.75;; 'voltage_3'=1.79V;;1.53:2.07;; 'voltage_4'=3.38V;;2.805:3.794;; 'voltage_5'=12.06V;;10.2:13.799;; 'voltage_6'=4.94V;;4.25:5.75;; 'voltage_7'=4.91V;;4.25:5.75;; 'voltage_8'=3.30V;;2.55:3.449;; 'count_fan'=3;;;; 'count_temperature'=3;;;; 'count_voltage'=9;;;;
    ...    6
    ...    --threshold-overload=temperature,CRITICAL,ok
    ...    CRITICAL: Temperature '0' status is 'ok' - Temperature '1' status is 'ok' - Temperature '2' status is 'ok' | 'fan_1'=7219rpm;;;; 'fan_2'=6923rpm;;;; 'fan_3'=7219rpm;;;; 'temperature_0'=42.75C;;0:60;; 'temperature_1'=36.00C;;0:60;; 'temperature_2'=40.00C;;0:60;; 'voltage_0'=1.00V;;0.85:1.15;; 'voltage_1'=0.99V;;0.85:1.15;; 'voltage_2'=4.90V;;4.25:5.75;; 'voltage_3'=1.79V;;1.53:2.07;; 'voltage_4'=3.38V;;2.805:3.794;; 'voltage_5'=12.06V;;10.2:13.799;; 'voltage_6'=4.94V;;4.25:5.75;; 'voltage_7'=4.91V;;4.25:5.75;; 'voltage_8'=3.30V;;2.55:3.449;; 'count_fan'=3;;;; 'count_temperature'=3;;;; 'count_voltage'=9;;;;
    ...    7
    ...    --warning=temperature,.*,30
    ...    WARNING: Temperature '0' is 42.75 - Temperature '1' is 36 - Temperature '2' is 40 | 'fan_1'=7219rpm;;;; 'fan_2'=6923rpm;;;; 'fan_3'=7219rpm;;;; 'temperature_0'=42.75C;0:30;;; 'temperature_1'=36.00C;0:30;;; 'temperature_2'=40.00C;0:30;;; 'voltage_0'=1.00V;;0.85:1.15;; 'voltage_1'=0.99V;;0.85:1.15;; 'voltage_2'=4.90V;;4.25:5.75;; 'voltage_3'=1.79V;;1.53:2.07;; 'voltage_4'=3.38V;;2.805:3.794;; 'voltage_5'=12.06V;;10.2:13.799;; 'voltage_6'=4.94V;;4.25:5.75;; 'voltage_7'=4.91V;;4.25:5.75;; 'voltage_8'=3.30V;;2.55:3.449;; 'count_fan'=3;;;; 'count_temperature'=3;;;; 'count_voltage'=9;;;;
    ...    8
    ...    --critical=temperature,.*,30
    ...    CRITICAL: Temperature '0' is 42.75 - Temperature '1' is 36 - Temperature '2' is 40 | 'fan_1'=7219rpm;;;; 'fan_2'=6923rpm;;;; 'fan_3'=7219rpm;;;; 'temperature_0'=42.75C;;0:30;; 'temperature_1'=36.00C;;0:30;; 'temperature_2'=40.00C;;0:30;; 'voltage_0'=1.00V;;0.85:1.15;; 'voltage_1'=0.99V;;0.85:1.15;; 'voltage_2'=4.90V;;4.25:5.75;; 'voltage_3'=1.79V;;1.53:2.07;; 'voltage_4'=3.38V;;2.805:3.794;; 'voltage_5'=12.06V;;10.2:13.799;; 'voltage_6'=4.94V;;4.25:5.75;; 'voltage_7'=4.91V;;4.25:5.75;; 'voltage_8'=3.30V;;2.55:3.449;; 'count_fan'=3;;;; 'count_temperature'=3;;;; 'count_voltage'=9;;;;

Hardware MS7000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms7000
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All 16 components are ok [4/4 fans, 5/5 temperatures, 7/7 voltages]. | 'fan_1'=4963rpm;;;; 'fan_2'=4927rpm;;;; 'fan_3'=5037rpm;;;; 'fan_4'=5192rpm;;;; 'temperature_0'=24.75C;;0:60;; 'temperature_1'=41.50C;;0:100;; 'temperature_2'=35.00C;;0:85;; 'temperature_3'=49.00C;;0:100;; 'temperature_4'=39.00C;;0:90;; 'voltage_0'=11.95V;;10.2:13.8;; 'voltage_1'=0.00V;;10.2:13.8;; 'voltage_2'=11.91V;;10.2:13.8;; 'voltage_3'=1.36V;;1.28:1.42;; 'voltage_4'=0.92V;;0.88:0.95;; 'voltage_5'=0.99V;;0.94:1.05;; 'voltage_6'=1.00V;;0.94:1.05;; 'count_fan'=4;;;; 'count_temperature'=5;;;; 'count_voltage'=7;;;;
    ...    2
    ...    --component=fan
    ...    OK: All 4 components are ok [4/4 fans]. | 'fan_1'=4963rpm;;;; 'fan_2'=4927rpm;;;; 'fan_3'=5037rpm;;;; 'fan_4'=5192rpm;;;; 'count_fan'=4;;;;
    ...    3
    ...    --filter=voltage
    ...    OK: All 9 components are ok [4/4 fans, 5/5 temperatures]. | 'fan_1'=4963rpm;;;; 'fan_2'=4927rpm;;;; 'fan_3'=5037rpm;;;; 'fan_4'=5192rpm;;;; 'temperature_0'=24.75C;;0:60;; 'temperature_1'=41.50C;;0:100;; 'temperature_2'=35.00C;;0:85;; 'temperature_3'=49.00C;;0:100;; 'temperature_4'=39.00C;;0:90;; 'count_fan'=4;;;; 'count_temperature'=5;;;;
    ...    5
    ...    --no-component=critical
    ...    OK: All 16 components are ok [4/4 fans, 5/5 temperatures, 7/7 voltages]. | 'fan_1'=4963rpm;;;; 'fan_2'=4927rpm;;;; 'fan_3'=5037rpm;;;; 'fan_4'=5192rpm;;;; 'temperature_0'=24.75C;;0:60;; 'temperature_1'=41.50C;;0:100;; 'temperature_2'=35.00C;;0:85;; 'temperature_3'=49.00C;;0:100;; 'temperature_4'=39.00C;;0:90;; 'voltage_0'=11.95V;;10.2:13.8;; 'voltage_1'=0.00V;;10.2:13.8;; 'voltage_2'=11.91V;;10.2:13.8;; 'voltage_3'=1.36V;;1.28:1.42;; 'voltage_4'=0.92V;;0.88:0.95;; 'voltage_5'=0.99V;;0.94:1.05;; 'voltage_6'=1.00V;;0.94:1.05;; 'count_fan'=4;;;; 'count_temperature'=5;;;; 'count_voltage'=7;;;;
    ...    6
    ...    --threshold-overload=temperature,CRITICAL,ok
    ...    CRITICAL: Temperature '0' status is 'ok' - Temperature '1' status is 'ok' - Temperature '2' status is 'ok' - Temperature '3' status is 'ok' - Temperature '4' status is 'ok' | 'fan_1'=4963rpm;;;; 'fan_2'=4927rpm;;;; 'fan_3'=5037rpm;;;; 'fan_4'=5192rpm;;;; 'temperature_0'=24.75C;;0:60;; 'temperature_1'=41.50C;;0:100;; 'temperature_2'=35.00C;;0:85;; 'temperature_3'=49.00C;;0:100;; 'temperature_4'=39.00C;;0:90;; 'voltage_0'=11.95V;;10.2:13.8;; 'voltage_1'=0.00V;;10.2:13.8;; 'voltage_2'=11.91V;;10.2:13.8;; 'voltage_3'=1.36V;;1.28:1.42;; 'voltage_4'=0.92V;;0.88:0.95;; 'voltage_5'=0.99V;;0.94:1.05;; 'voltage_6'=1.00V;;0.94:1.05;; 'count_fan'=4;;;; 'count_temperature'=5;;;; 'count_voltage'=7;;;;
    ...    7
    ...    --warning=temperature,.*,30
    ...    WARNING: Temperature '1' is 41.5 - Temperature '2' is 35 - Temperature '3' is 49 - Temperature '4' is 39 | 'fan_1'=4963rpm;;;; 'fan_2'=4927rpm;;;; 'fan_3'=5037rpm;;;; 'fan_4'=5192rpm;;;; 'temperature_0'=24.75C;0:30;;; 'temperature_1'=41.50C;0:30;;; 'temperature_2'=35.00C;0:30;;; 'temperature_3'=49.00C;0:30;;; 'temperature_4'=39.00C;0:30;;; 'voltage_0'=11.95V;;10.2:13.8;; 'voltage_1'=0.00V;;10.2:13.8;; 'voltage_2'=11.91V;;10.2:13.8;; 'voltage_3'=1.36V;;1.28:1.42;; 'voltage_4'=0.92V;;0.88:0.95;; 'voltage_5'=0.99V;;0.94:1.05;; 'voltage_6'=1.00V;;0.94:1.05;; 'count_fan'=4;;;; 'count_temperature'=5;;;; 'count_voltage'=7;;;;
    ...    8
    ...    --critical=temperature,.*,30
    ...    CRITICAL: Temperature '1' is 41.5 - Temperature '2' is 35 - Temperature '3' is 49 - Temperature '4' is 39 | 'fan_1'=4963rpm;;;; 'fan_2'=4927rpm;;;; 'fan_3'=5037rpm;;;; 'fan_4'=5192rpm;;;; 'temperature_0'=24.75C;;0:30;; 'temperature_1'=41.50C;;0:30;; 'temperature_2'=35.00C;;0:30;; 'temperature_3'=49.00C;;0:30;; 'temperature_4'=39.00C;;0:30;; 'voltage_0'=11.95V;;10.2:13.8;; 'voltage_1'=0.00V;;10.2:13.8;; 'voltage_2'=11.91V;;10.2:13.8;; 'voltage_3'=1.36V;;1.28:1.42;; 'voltage_4'=0.92V;;0.88:0.95;; 'voltage_5'=0.99V;;0.94:1.05;; 'voltage_6'=1.00V;;0.94:1.05;; 'count_fan'=4;;;; 'count_temperature'=5;;;; 'count_voltage'=7;;;;
