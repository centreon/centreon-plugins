*** Settings ***
Documentation       Check cpu table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin
${CGS_COLLECTIONS}      ${CURDIR}${/}..${/}..${/}..${/}..${/}rust-plugins${/}rs-collections${/}applications-protocol-snmp


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
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CGS_COLLECTIONS}${/}cpu.json
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
    ...    OK: 1 CPU(s) average usage is 2.00 % - CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;;0;100
    ...    2
    ...    --warning-average=0
    ...    WARNING: 1 CPU(s) average usage is 2.00 % | 'total_cpu_avg'=2.00%;0:0;;0;100 'cpu'=2.00%;;;0;100
    ...    3
    ...    --critical-average=0
    ...    CRITICAL: 1 CPU(s) average usage is 2.00 % | 'total_cpu_avg'=2.00%;;0:0;0;100 'cpu'=2.00%;;;0;100
    ...    4
    ...    --warning-core=0
    ...    WARNING: CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;0:0;;0;100
    ...    5
    ...    --critical-core=0
    ...    CRITICAL: CPU '0' usage : 2.00 % | 'total_cpu_avg'=2.00%;;;0;100 'cpu'=2.00%;;0:0;0;100
