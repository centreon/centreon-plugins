*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS}
${CGS_COLLECTIONS}      ${CURDIR}${/}..${/}..${/}..${/}..${/}rust-plugins${/}rs-collections${/}operatingsystems-windows-snmp


*** Test Cases ***
uptime ${tc}
    [Tags]    os    windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=uptime
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options    expected_result    --
    ...    1    --warning-uptime='2'    WARNING: System uptime is: 18m 37s | 'uptime'=1117.00s;0:2;;0;
    ...    2    --warning-uptime='1'    WARNING: System uptime is: 18m 37s | 'uptime'=1117.00s;0:1;;0;
    ...    3    --critical-uptime='2'    CRITICAL: System uptime is: 18m 37s | 'uptime'=1117.00s;;0:2;0;
    ...    4    --add-sysdesc    OK: System uptime is: 18m 37s, - | 'uptime'=1117.00s;;;0;
    ...    5    --critical-uptime='1'    CRITICAL: System uptime is: 18m 37s | 'uptime'=1117.00s;;0:1;0;
    ...    6    --check-overload    OK: System uptime is: 18m 37s | 'uptime'=1117.00s;;;0;
    ...    7    --reboot-window    OK: System uptime is: 18m 37s | 'uptime'=1117.00s;;;0;
    ...    8    --unit='h'    OK: System uptime is: 18m 37s | 'uptime'=0.31h;;;0;
    ...    9    --unit='m'    OK: System uptime is: 18m 37s | 'uptime'=18.62m;;;0;
    ...    10    --unit='s'    OK: System uptime is: 18m 37s | 'uptime'=1117.00s;;;0;

cgs-uptime ${tc}
    [Tags]    os    windows    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CGS_COLLECTIONS}${/}..${/}applications-protocol-snmp${/}uptime.json
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
    ...    OK: Uptime: 1117.12s | system.uptime.seconds=1117.12s;;;0;
    ...    2
    ...    --warning-seconds=1:1
    ...    WARNING: system.uptime.seconds is 1117.12s | system.uptime.seconds=1117.12s;1:1;;0;
    ...    3
    ...    --critical-seconds=1:1
    ...    CRITICAL: system.uptime.seconds is 1117.12s | system.uptime.seconds=1117.12s;;1:1;0;
