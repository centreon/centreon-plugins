*** Settings ***
Documentation       Hardware UPS powerware SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=hardware::ups::powerware::snmp::plugin
...         --mode=input-lines
...         --hostname=${HOSTNAME}
...         --snmp-version=${SNMPVERSION}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=hardware/ups/powerware/snmp/inputlines
...         --snmp-timeout=1


*** Test Cases ***
Hardware UPS Standard SNMP input lines ${tc}
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
    ...    OK: frequency: 0.00 Hz - All input lines are ok | 'frequency'=0.00Hz;;;; 'current_1'=1.00A;;;0; 'power_1'=1.00W;;;; 'current_2'=5.00A;;;0; 'voltage_2'=231.00V;;190:260;; 'power_2'=1155.00W;;;; 'current_3'=4.00A;;;0; 'voltage_3'=228.00V;;190:260;; 'power_3'=912.00W;;;;
    ...    2
    ...    --filter-iline=2
    ...    OK: frequency: 0.00 Hz - Input Line '2' current: 5.00 A, voltage: 231.00 V, power: 1155.00 W | 'frequency'=0.00Hz;;;; 'current'=5.00A;;;0; 'voltage'=231.00V;;190:260;; 'power'=1155.00W;;;;
    ...    3
    ...    --warning-current=:1
    ...    WARNING: Input Line '2' current: 5.00 A - Input Line '3' current: 4.00 A | 'frequency'=0.00Hz;;;; 'current_1'=1.00A;0:1;;0; 'power_1'=1.00W;;;; 'current_2'=5.00A;0:1;;0; 'voltage_2'=231.00V;;190:260;; 'power_2'=1155.00W;;;; 'current_3'=4.00A;0:1;;0; 'voltage_3'=228.00V;;190:260;; 'power_3'=912.00W;;;;
    ...    4
    ...    --critical-current=:1
    ...    CRITICAL: Input Line '2' current: 5.00 A - Input Line '3' current: 4.00 A | 'frequency'=0.00Hz;;;; 'current_1'=1.00A;;0:1;0; 'power_1'=1.00W;;;; 'current_2'=5.00A;;0:1;0; 'voltage_2'=231.00V;;190:260;; 'power_2'=1155.00W;;;; 'current_3'=4.00A;;0:1;0; 'voltage_3'=228.00V;;190:260;; 'power_3'=912.00W;;;;
    ...    5
    ...    --warning-frequency=1:
    ...    WARNING: frequency: 0.00 Hz | 'frequency'=0.00Hz;1:;;; 'current_1'=1.00A;;;0; 'power_1'=1.00W;;;; 'current_2'=5.00A;;;0; 'voltage_2'=231.00V;;190:260;; 'power_2'=1155.00W;;;; 'current_3'=4.00A;;;0; 'voltage_3'=228.00V;;190:260;; 'power_3'=912.00W;;;;
    ...    6
    ...    --critical-frequency=1:
    ...    CRITICAL: frequency: 0.00 Hz | 'frequency'=0.00Hz;;1:;; 'current_1'=1.00A;;;0; 'power_1'=1.00W;;;; 'current_2'=5.00A;;;0; 'voltage_2'=231.00V;;190:260;; 'power_2'=1155.00W;;;; 'current_3'=4.00A;;;0; 'voltage_3'=228.00V;;190:260;; 'power_3'=912.00W;;;;
    ...    7
    ...    --warning-power=:1
    ...    WARNING: Input Line '2' power: 1155.00 W - Input Line '3' power: 912.00 W | 'frequency'=0.00Hz;;;; 'current_1'=1.00A;;;0; 'power_1'=1.00W;0:1;;; 'current_2'=5.00A;;;0; 'voltage_2'=231.00V;;190:260;; 'power_2'=1155.00W;0:1;;; 'current_3'=4.00A;;;0; 'voltage_3'=228.00V;;190:260;; 'power_3'=912.00W;0:1;;;
    ...    8
    ...    --critical-power=:1
    ...    CRITICAL: Input Line '2' power: 1155.00 W - Input Line '3' power: 912.00 W | 'frequency'=0.00Hz;;;; 'current_1'=1.00A;;;0; 'power_1'=1.00W;;0:1;; 'current_2'=5.00A;;;0; 'voltage_2'=231.00V;;190:260;; 'power_2'=1155.00W;;0:1;; 'current_3'=4.00A;;;0; 'voltage_3'=228.00V;;190:260;; 'power_3'=912.00W;;0:1;;
    ...    9
    ...    --warning-voltage=1:
    ...    WARNING: Input Line '1' voltage: 0.00 V | 'frequency'=0.00Hz;;;; 'current_1'=1.00A;;;0; 'voltage_1'=0.00V;1:;;; 'power_1'=1.00W;;;; 'current_2'=5.00A;;;0; 'voltage_2'=231.00V;1:;;; 'power_2'=1155.00W;;;; 'current_3'=4.00A;;;0; 'voltage_3'=228.00V;1:;;; 'power_3'=912.00W;;;;
    ...    10
    ...    --critical-voltage=1:
    ...    CRITICAL: Input Line '1' voltage: 0.00 V | 'frequency'=0.00Hz;;;; 'current_1'=1.00A;;;0; 'voltage_1'=0.00V;;1:;; 'power_1'=1.00W;;;; 'current_2'=5.00A;;;0; 'voltage_2'=231.00V;;1:;; 'power_2'=1155.00W;;;; 'current_3'=4.00A;;;0; 'voltage_3'=228.00V;;1:;; 'power_3'=912.00W;;;;
    ...    11
    ...    --warning-frequence=1:
    ...    WARNING: frequency: 0.00 Hz | 'frequency'=0.00Hz;1:;;; 'current_1'=1.00A;;;0; 'power_1'=1.00W;;;; 'current_2'=5.00A;;;0; 'voltage_2'=231.00V;;190:260;; 'power_2'=1155.00W;;;; 'current_3'=4.00A;;;0; 'voltage_3'=228.00V;;190:260;; 'power_3'=912.00W;;;;
    ...    12
    ...    --critical-frequence=1:
    ...    CRITICAL: frequency: 0.00 Hz | 'frequency'=0.00Hz;;1:;; 'current_1'=1.00A;;;0; 'power_1'=1.00W;;;; 'current_2'=5.00A;;;0; 'voltage_2'=231.00V;;190:260;; 'power_2'=1155.00W;;;; 'current_3'=4.00A;;;0; 'voltage_3'=228.00V;;190:260;; 'power_3'=912.00W;;;;
