*** Settings ***
Documentation       hardware::ups::phoenixtec::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=hardware::ups::phoenixtec::snmp::plugin
...         --mode=output-lines
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=hardware/ups/phoenixtec/snmp/outputlines


*** Test Cases ***
Outputlines ${tc}
    [Tags]    hardware    ups    snmp
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
    ...    OK: Output lines status is 'onLine', load: 37.00 %, frequency: 50.00 Hz, voltage: 23 V | 'lines.output.load.percentage'=37.00;;;0;100 'lines.output.frequency.hertz'=50.00Hz;;;; 'lines.output.voltage.volt'=23V;;;;
    ...    2
    ...    --warning-frequence=:1
    ...    WARNING: Output lines frequency: 50.00 Hz | 'lines.output.load.percentage'=37.00;;;0;100 'lines.output.frequency.hertz'=50.00Hz;0:1;;; 'lines.output.voltage.volt'=23V;;;;
    ...    3
    ...    --critical-frequence=:1
    ...    CRITICAL: Output lines frequency: 50.00 Hz | 'lines.output.load.percentage'=37.00;;;0;100 'lines.output.frequency.hertz'=50.00Hz;;0:1;; 'lines.output.voltage.volt'=23V;;;;
    ...    4
    ...    --warning-lines-output-frequence-hertz=:1
    ...    WARNING: Output lines frequency: 50.00 Hz | 'lines.output.load.percentage'=37.00;;;0;100 'lines.output.frequency.hertz'=50.00Hz;0:1;;; 'lines.output.voltage.volt'=23V;;;;
    ...    5
    ...    --critical-lines-output-frequence-hertz=:1
    ...    CRITICAL: Output lines frequency: 50.00 Hz | 'lines.output.load.percentage'=37.00;;;0;100 'lines.output.frequency.hertz'=50.00Hz;;0:1;; 'lines.output.voltage.volt'=23V;;;;
    ...    6
    ...    --warning-frequency=:1
    ...    WARNING: Output lines frequency: 50.00 Hz | 'lines.output.load.percentage'=37.00;;;0;100 'lines.output.frequency.hertz'=50.00Hz;0:1;;; 'lines.output.voltage.volt'=23V;;;;
    ...    7
    ...    --critical-frequency=:1
    ...    CRITICAL: Output lines frequency: 50.00 Hz | 'lines.output.load.percentage'=37.00;;;0;100 'lines.output.frequency.hertz'=50.00Hz;;0:1;; 'lines.output.voltage.volt'=23V;;;;
    ...    8
    ...    --warning-load=:1
    ...    WARNING: Output lines load: 37.00 % | 'lines.output.load.percentage'=37.00;0:1;;0;100 'lines.output.frequency.hertz'=50.00Hz;;;; 'lines.output.voltage.volt'=23V;;;;
    ...    9
    ...    --critical-load=:1
    ...    CRITICAL: Output lines load: 37.00 % | 'lines.output.load.percentage'=37.00;;0:1;0;100 'lines.output.frequency.hertz'=50.00Hz;;;; 'lines.output.voltage.volt'=23V;;;;
    ...    10
    ...    --warning-voltage=:1
    ...    WARNING: Output lines voltage: 23 V | 'lines.output.load.percentage'=37.00;;;0;100 'lines.output.frequency.hertz'=50.00Hz;;;; 'lines.output.voltage.volt'=23V;0:1;;;
    ...    11
    ...    --critical-voltage=:1
    ...    CRITICAL: Output lines voltage: 23 V | 'lines.output.load.percentage'=37.00;;;0;100 'lines.output.frequency.hertz'=50.00Hz;;;; 'lines.output.voltage.volt'=23V;;0:1;;
