*** Settings ***
Documentation       Check cpu table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}          ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin
${CGS_CMD}      ${CENTREON_PLUGIN_RUST_SNMP} -j ${CURDIR}${/}generic-snmp/cpu.json


*** Test Cases ***
cpu ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/network-interfaces
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
    ...    2
    ...    --warning-average='0'
    ...    WARNING: 1 CPU(s) average usage is 2.00 % | 'total_cpu_avg'=2.00%;0:0;;0;100 'cpu'=2.00%;;;0;100
    ...    3
    ...    --critical-average='0'
    ...    CRITICAL: 1 CPU(s) average usage is 2.00 % | 'total_cpu_avg'=2.00%;;0:0;0;100 'cpu'=2.00%;;;0;100
    ...    4
    ...    --warning-core='0'
    ...    WARNING: CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;0:0;;0;100
    ...    5
    ...    --critical-core='0'
    ...    CRITICAL: CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;0:0;0;100

cgs-cpu ${tc}
    [Tags]    os    linux    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CGS_CMD}
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/linux/snmp/network-interfaces
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: avg.cpu.usage.percent is 2% | 0#core.cpu.usage.percent=2%;;;0;100 avg.cpu.usage.percent=2%;;;0;100
    ...    2
    ...    --warning-avg=0.1
    ...    WARNING: avg.cpu.usage.percent is 2% | 0#core.cpu.usage.percent=2%;;;0;100 avg.cpu.usage.percent=2%;0.1;;0;100
    ...    3
    ...    --critical-avg=0.1
    ...    CRITICAL: avg.cpu.usage.percent is 2% | 0#core.cpu.usage.percent=2%;;;0;100 avg.cpu.usage.percent=2%;;0.1;0;100
    ...    4
    ...    --warning-cpu=0.1
    ...    WARNING: 0#core.cpu.usage.percent is 2% | 0#core.cpu.usage.percent=2%;0.1;;0;100 avg.cpu.usage.percent=2%;;;0;100
    ...    5
    ...    --critical-cpu=0.01
    ...    CRITICAL: 0#core.cpu.usage.percent is 2% | 0#core.cpu.usage.percent=2%;;0.01;0;100 avg.cpu.usage.percent=2%;;;0;100


cgs-error ${tc}
    [Tags]    os    linux    centreon-plugin-rust-snmp    panic
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j
    ...    ${CURDIR}${/}generic-snmp/err-invalid-oid.json
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/linux/snmp/network-interfaces
    ...    2>/dev/null

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    UNKNOWN: Could not parse oid 1.3.6.1.2.a.25.3.3.1.2

cgs-no-connection ${tc}
    [Tags]    os    linux    centreon-plugin-rust-snmp    panic
    ${command}    Catenate
        ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j
    ...    ${CURDIR}${/}generic-snmp/cpu.json
    ...    --hostname=127.0.0.1
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/linux/snmp/network-interfaces
    ...    ${option}
    ...    2>/dev/null

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}
    Examples:
    ...    tc
    ...    option
    ...    expected_result
    ...    --
    ...    1
    ...    --hostname='128.0.20.20'
    ...    UNKNOWN: Could not connect to 128.0.20.20:2024 is the hostname and the snmp community correct ? Resource temporarily unavailable (os error 11)
    ...    2
    ...    --snmp-community='badCommunity'
    ...    UNKNOWN: Could not connect to 127.0.0.1:2024 is the hostname and the snmp community correct ? Resource temporarily unavailable (os error 11)
