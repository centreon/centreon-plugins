*** Settings ***
Documentation       check various centreon-plugin-rust-snmp error cases

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin
${CGS_COLLECTIONS}      ${CURDIR}${/}..${/}..${/}..${/}..${/}rust-plugins${/}rs-collections${/}rust-snmp


*** Test Cases ***
cgs-invalid-oid
    [Tags]    os    linux    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CURDIR}${/}generic-snmp/err-invalid-oid.json
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/linux/snmp/network-interfaces
    ...    2>/dev/null

    Ctn Run Command Without Connector And Check Result As Strings
    ...    ${command}
    ...    UNKNOWN: Could not parse oid 1.3.6.1.2.a.25.3.3.1.2

cgs-invalid-macro
    [Tags]    os    linux    centreon-plugin-rust-snmp    panic
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CURDIR}${/}generic-snmp/err-macro.json
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/linux/snmp/network-interfaces
    ...    2>/dev/null

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    UNKNOWN.*usage\.percent.*value

cgs-no-connection ${tc}
    [Tags]    os    linux    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CGS_COLLECTIONS}${/}cpu.json
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
