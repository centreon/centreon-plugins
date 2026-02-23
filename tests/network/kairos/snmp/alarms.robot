*** Settings ***
Documentation       network::kairos::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::kairos::snmp::plugin
...         --mode=alarms
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/kairos/snmp/kairos-ent


*** Test Cases ***
Alarms ${tc}
    [Tags]    network    kairos    snmp
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
    ...    OK: All alarms are ok
    ...    2
    ...    --filter-instance=20 --warning-count=1:
    ...    OK: count : Buffer creation
    ...    3
    ...    --filter-instance=20 --warning-count=1:
    ...    WARNING: alarm 'Synchronization Status' count: 0 [Synch] | 'alarm.Synch.count'=0;1:;;;
    ...    4
    ...    --filter-instance=20 --critical-count=1:
    ...    CRITICAL: alarm 'Synchronization Status' count: 0 [Synch] | 'alarm.Synch.count'=0;;1:;;
    ...    5
    ...    --filter-name=SipReg 
    ...    OK: All alarms are ok
    ...    6
    ...    --filter-name=SipReg --critical-count=1:
    ...    CRITICAL: alarm 'Fail to Register to SIP' count: 0 [FailSipReg] - alarm 'Registration to SIP' count: 0 [SipReg] | 'alarm.FailSipReg.count'=0;;1:;; 'alarm.SipReg.count'=0;;1:;;
