*** Settings ***
Documentation       network::waystream::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::waystream::snmp::plugin
...         --mode=cpu
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}


*** Test Cases ***
Cpu MS4000 ${tc}
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
    ...    OK: 1 CPU(s) average usage is 12.00 % - CPU '0' usage : 12.00 % | 'cpu.utilization.percentage'=12.00%;;;0;100 '0#core.cpu.utilization.percentage'=12.00%;;;0;100
    ...    2
    ...    --use-ucd=1
    ...    UNKNOWN: SNMP GET Request: Cant get a single value.
    ...    3
    ...    --warning-average=1
    ...    WARNING: 1 CPU(s) average usage is 12.00 % | 'cpu.utilization.percentage'=12.00%;0:1;;0;100 '0#core.cpu.utilization.percentage'=12.00%;;;0;100
    ...    4
    ...    --critical-average=1
    ...    CRITICAL: 1 CPU(s) average usage is 12.00 % | 'cpu.utilization.percentage'=12.00%;;0:1;0;100 '0#core.cpu.utilization.percentage'=12.00%;;;0;100
    ...    5
    ...    --warning-core=1
    ...    WARNING: CPU '0' usage : 12.00 % | 'cpu.utilization.percentage'=12.00%;;;0;100 '0#core.cpu.utilization.percentage'=12.00%;0:1;;0;100
    ...    6
    ...    --critical-core=1
    ...    CRITICAL: CPU '0' usage : 12.00 % | 'cpu.utilization.percentage'=12.00%;;;0;100 '0#core.cpu.utilization.percentage'=12.00%;;0:1;0;100

Cpu MS7000 ${tc}
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
    ...    OK: 1 CPU(s) average usage is 4.00 % - CPU '0' usage : 4.00 % | 'cpu.utilization.percentage'=4.00%;;;0;100 '0#core.cpu.utilization.percentage'=4.00%;;;0;100
    ...    2
    ...    --use-ucd=1
    ...    UNKNOWN: SNMP GET Request: Cant get a single value.
    ...    3
    ...    --warning-average=1
    ...    WARNING: 1 CPU(s) average usage is 4.00 % | 'cpu.utilization.percentage'=4.00%;0:1;;0;100 '0#core.cpu.utilization.percentage'=4.00%;;;0;100
    ...    4
    ...    --critical-average=1
    ...    CRITICAL: 1 CPU(s) average usage is 4.00 % | 'cpu.utilization.percentage'=4.00%;;0:1;0;100 '0#core.cpu.utilization.percentage'=4.00%;;;0;100
    ...    5
    ...    --warning-core=1
    ...    WARNING: CPU '0' usage : 4.00 % | 'cpu.utilization.percentage'=4.00%;;;0;100 '0#core.cpu.utilization.percentage'=4.00%;0:1;;0;100
    ...    6
    ...    --critical-core=1
    ...    CRITICAL: CPU '0' usage : 4.00 % | 'cpu.utilization.percentage'=4.00%;;;0;100 '0#core.cpu.utilization.percentage'=4.00%;;0:1;0;100
