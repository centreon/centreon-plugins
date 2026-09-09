*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS}
${CGS_COLLECTIONS}      ${CURDIR}${/}..${/}..${/}..${/}..${/}rust-plugins${/}rs-collections${/}applications-protocol-snmp


*** Test Cases ***
cpu ${tc}
    [Tags]    os    windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    --snmp-timeout=1
    ...    --critical-average=${critical-average}
    ...    --warning-average=${warning-average}
    ...    --warning-core=${warning-core}
    ...    --critical-core=${critical-core}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    critical-average
    ...    warning-average
    ...    warning-core
    ...    critical-core
    ...    expected_result
    ...    --
    ...    2
    ...    '90'
    ...    '80'
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    OK: 2 CPU(s) average usage is 0.50 % | 'total_cpu_avg'=0.50%;0:80;0:90;0;100 'cpu_0'=1.00%;;;0;100 'cpu_1'=0.00%;;;0;100
    ...    3
    ...    '1180'
    ...    '0'
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    WARNING: 2 CPU(s) average usage is 0.50 % | 'total_cpu_avg'=0.50%;0:0;0:1180;0;100 'cpu_0'=1.00%;;;0;100 'cpu_1'=0.00%;;;0;100
    ...    4
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    '0'
    ...    '0'
    ...    CRITICAL: CPU '0' usage : 1.00 % | 'total_cpu_avg'=0.50%;;;0;100 'cpu_0'=1.00%;0:0;0:0;0;100 'cpu_1'=0.00%;0:0;0:0;0;100
    ...    5
    ...    '0'
    ...    '0'
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    CRITICAL: 2 CPU(s) average usage is 0.50 % | 'total_cpu_avg'=0.50%;0:0;0:0;0;100 'cpu_0'=1.00%;;;0;100 'cpu_1'=0.00%;;;0;100

cgs-cpu ${tc}
    [Tags]    os    windows    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CGS_COLLECTIONS}${/}cpu.json
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: 2 CPU(s) average usage is 0.50 % | 'total_cpu_avg'=0.50%;;;0;100 '0#cpu'=1.00%;;;0;100 '1#cpu'=0.00%;;;0;100
    ...    2
    ...    --warning-average=0
    ...    WARNING: 2 CPU(s) average usage is 0.50 % | 'total_cpu_avg'=0.50%;0:0;;0;100 '0#cpu'=1.00%;;;0;100 '1#cpu'=0.00%;;;0;100
    ...    3
    ...    --critical-average=0
    ...    CRITICAL: 2 CPU(s) average usage is 0.50 % | 'total_cpu_avg'=0.50%;;0:0;0;100 '0#cpu'=1.00%;;;0;100 '1#cpu'=0.00%;;;0;100
    ...    4
    ...    --warning-core=0
    ...    WARNING: CPU '0' usage : 1.00 % - CPU '1' usage : 0.00 % | 'total_cpu_avg'=0.50%;;;0;100 '0#cpu'=1.00%;0:0;;0;100 '1#cpu'=0.00%;0:0;;0;100
    ...    5
    ...    --critical-core=0
    ...    CRITICAL: CPU '0' usage : 1.00 % - CPU '1' usage : 0.00 % | 'total_cpu_avg'=0.50%;;;0;100 '0#cpu'=1.00%;;0:0;0;100 '1#cpu'=0.00%;;0:0;0;100
