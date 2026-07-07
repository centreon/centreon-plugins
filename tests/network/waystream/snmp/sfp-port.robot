*** Settings ***
Documentation       network::waystream::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::waystream::snmp::plugin
...         --mode=sfp-port
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}


*** Test Cases ***
Sfp-port MS4000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms4000
    ...    --include-port=^1\\\\$
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: sfp port '1' [serial: S1902216386] status : ok (Temp: ok, RX: ok, TX: ok, Bias: ok, Volt: ok) | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    2
    ...    --warning-status=1
    ...    WARNING: sfp port '1' [serial: S1902216386] status : ok (Temp: ok, RX: ok, TX: ok, Bias: ok, Volt: ok) | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    3
    ...    --critical-status=1
    ...    CRITICAL: sfp port '1' [serial: S1902216386] status : ok (Temp: ok, RX: ok, TX: ok, Bias: ok, Volt: ok) | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    4
    ...    --warning-rx-input-power=0:0
    ...    WARNING: sfp port '1' [serial: S1902216386] input power: 0.14 mW | '1#port.input.power.milliwatt'=0.14mW;0:0;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    5
    ...    --critical-rx-input-power=0:0
    ...    CRITICAL: sfp port '1' [serial: S1902216386] input power: 0.14 mW | '1#port.input.power.milliwatt'=0.14mW;;0:0;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    6
    ...    --warning-rx-input-power-dbm=1
    ...    WARNING: sfp port '1' [serial: S1902216386] input power: -8.42 dBm | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;0:1;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    7
    ...    --critical-rx-input-power-dbm=1
    ...    CRITICAL: sfp port '1' [serial: S1902216386] input power: -8.42 dBm | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;0:1;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    8
    ...    --warning-tx-output-power=0:0
    ...    WARNING: sfp port '1' [serial: S1902216386] output power: 0.26 mW | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;0:0;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    9
    ...    --critical-tx-output-power=0:0
    ...    CRITICAL: sfp port '1' [serial: S1902216386] output power: 0.26 mW | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;0:0;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    10
    ...    --warning-tx-output-power-dbm=1
    ...    WARNING: sfp port '1' [serial: S1902216386] output power: -5.89 dBm | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;0:1;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    11
    ...    --critical-tx-output-power-dbm=1
    ...    CRITICAL: sfp port '1' [serial: S1902216386] output power: -5.89 dBm | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;0:1;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    12
    ...    --warning-bias-current=1
    ...    WARNING: sfp port '1' [serial: S1902216386] Bias Current : 39.00 mA | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;0:1;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    13
    ...    --critical-bias-current=1
    ...    CRITICAL: sfp port '1' [serial: S1902216386] Bias Current : 39.00 mA | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;0:1;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    14
    ...    --warning-temperature=1
    ...    WARNING: sfp port '1' [serial: S1902216386] temperature: 40.00 C | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;0:1;;; '1#port.voltage.volt'=3.40V;;;;
    ...    15
    ...    --critical-temperature=1
    ...    CRITICAL: sfp port '1' [serial: S1902216386] temperature: 40.00 C | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;0:1;; '1#port.voltage.volt'=3.40V;;;;
    ...    16
    ...    --warning-volt=1
    ...    WARNING: sfp port '1' [serial: S1902216386] Voltage : 3.40 V | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;0:1;;;
    ...    17
    ...    --critical-volt=1
    ...    CRITICAL: sfp port '1' [serial: S1902216386] Voltage : 3.40 V | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;0:1;;
    ...    18
    ...    --warning-bitrate=1
    ...    WARNING: sfp port '1' [serial: S1902216386] Bitrate : 1.30 Gb/s | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;0:1;;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;
    ...    19
    ...    --critical-bitrate=1
    ...    CRITICAL: sfp port '1' [serial: S1902216386] Bitrate : 1.30 Gb/s | '1#port.input.power.milliwatt'=0.14mW;;;; '1#port.input.power.dbm'=-8.42dBm;;;; '1#port.output.power.milliwatt'=0.26mW;;;; '1#port.output.power.dbm'=-5.89dBm;;;; '1#port.bias.current.milliampere'=39.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;0:1;; '1#port.temperature.celsius'=40C;;;; '1#port.voltage.volt'=3.40V;;;;

Sfp-port MS7000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms7000
    ...    --include-port=^1\\\\$
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    2
    ...    --warning-status=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    3
    ...    --critical-status=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    4
    ...    --warning-rx-input-power=0:0
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) | '1#port.input.power.milliwatt'=0.00mW;0:0;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    5
    ...    --critical-rx-input-power=0:0
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) | '1#port.input.power.milliwatt'=0.00mW;;0:0;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    6
    ...    --warning-rx-input-power-dbm=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) WARNING: sfp port '1' [serial: S1904125903] input power: -40.00 dBm | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;0:1;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    7
    ...    --critical-rx-input-power-dbm=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) - input power: -40.00 dBm | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;0:1;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    8
    ...    --warning-tx-output-power=0:0
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) WARNING: sfp port '1' [serial: S1904125903] output power: 0.25 mW | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;0:0;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    9
    ...    --critical-tx-output-power=0:0
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) - output power: 0.25 mW | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;0:0;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    10
    ...    --warning-tx-output-power-dbm=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) WARNING: sfp port '1' [serial: S1904125903] output power: -5.95 dBm | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;0:1;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    11
    ...    --critical-tx-output-power-dbm=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) - output power: -5.95 dBm | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;0:1;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    12
    ...    --warning-bias-current=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) WARNING: sfp port '1' [serial: S1904125903] Bias Current : 26.00 mA | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;0:1;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    13
    ...    --critical-bias-current=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) - Bias Current : 26.00 mA | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;0:1;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    14
    ...    --warning-temperature=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) WARNING: sfp port '1' [serial: S1904125903] temperature: 45.00 C | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;0:1;;; '1#port.voltage.volt'=3.31V;;;;
    ...    15
    ...    --critical-temperature=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) - temperature: 45.00 C | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;0:1;; '1#port.voltage.volt'=3.31V;;;;
    ...    16
    ...    --warning-volt=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) WARNING: sfp port '1' [serial: S1904125903] Voltage : 3.31 V | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;0:1;;;
    ...    17
    ...    --critical-volt=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) - Voltage : 3.31 V | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;0:1;;
    ...    18
    ...    --warning-bitrate=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) WARNING: sfp port '1' [serial: S1904125903] Bitrate : 1.30 Gb/s | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;0:1;;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
    ...    19
    ...    --critical-bitrate=1
    ...    CRITICAL: sfp port '1' [serial: S1904125903] status : ok (Temp: ok, RX: ok, TX: alarmLow, Bias: ok, Volt: ok) - Bitrate : 1.30 Gb/s | '1#port.input.power.milliwatt'=0.00mW;;;; '1#port.input.power.dbm'=-40.00dBm;;;; '1#port.output.power.milliwatt'=0.25mW;;;; '1#port.output.power.dbm'=-5.95dBm;;;; '1#port.bias.current.milliampere'=26.00mA;;;; '1#port.bitrate.bitspersecond'=1300000000b/s;;0:1;; '1#port.temperature.celsius'=45C;;;; '1#port.voltage.volt'=3.31V;;;;
