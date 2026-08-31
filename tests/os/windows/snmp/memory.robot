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
memory ${tc}
    [Tags]    os    windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --verbose
    ...    OK: Ram Total: 4.00GB Used: 557.94MB (13.62%) Free: 3.45GB (86.38%) | 'used'=585039872B;;;0;4294377472
    ...    2
    ...    --warning-memory='80'
    ...    OK: Ram Total: 4.00GB Used: 557.94MB (13.62%) Free: 3.45GB (86.38%) | 'used'=585039872B;0:3435501977;;0;4294377472
    ...    3
    ...    --units
    ...    OK: Ram Total: 4.00GB Used: 557.94MB (13.62%) Free: 3.45GB (86.38%) | 'used'=585039872B;;;0;4294377472
    ...    4
    ...    --free
    ...    OK: Ram Total: 4.00GB Used: 557.94MB (13.62%) Free: 3.45GB (86.38%) | 'memory.free.bytes'=3709337600B;;;0;4294377472
    ...    5
    ...    --critical-memory='90' --warning-memory='80'
    ...    OK: Ram Total: 4.00GB Used: 557.94MB (13.62%) Free: 3.45GB (86.38%) | 'used'=585039872B;0:3435501977;0:3864939724;0;4294377472
    ...    6
    ...    --critical-memory='0'
    ...    CRITICAL: Ram Total: 4.00GB Used: 557.94MB (13.62%) Free: 3.45GB (86.38%) | 'used'=585039872B;;0:0;0;4294377472
    ...    7
    ...    --warning-memory='0'
    ...    WARNING: Ram Total: 4.00GB Used: 557.94MB (13.62%) Free: 3.45GB (86.38%) | 'used'=585039872B;0:0;;0;4294377472

cgs-memory ${tc}
    [Tags]    os    windows    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CGS_COLLECTIONS}${/}memory.json
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
    ...    --filter-in='Physical Memory'
    ...    OK: 'Physical Memory#memory.usage.percent' is 13.62%, 'Physical Memory#memory.usage.bytes' is 585039872B | 'Physical Memory#memory.usage.percent'=13.62%;;;0;100 'Physical Memory#memory.usage.bytes'=585039872B;;;0;4294377472
    ...    2
    ...    --filter-in='Physical Memory' --warning-bytes=0.1
    ...    WARNING: 'Physical Memory#memory.usage.bytes' is 585039872B | 'Physical Memory#memory.usage.percent'=13.62%;;;0;100 'Physical Memory#memory.usage.bytes'=585039872B;0.1;;0;4294377472
    ...    3
    ...    --filter-in='Physical Memory' --critical-bytes=0.1
    ...    CRITICAL: 'Physical Memory#memory.usage.bytes' is 585039872B | 'Physical Memory#memory.usage.percent'=13.62%;;;0;100 'Physical Memory#memory.usage.bytes'=585039872B;;0.1;0;4294377472
    ...    4
    ...    --filter-in='Physical Memory' --warning-prct=0.1
    ...    WARNING: 'Physical Memory#memory.usage.percent' is 13.62% | 'Physical Memory#memory.usage.percent'=13.62%;0.1;;0;100 'Physical Memory#memory.usage.bytes'=585039872B;;;0;4294377472
    ...    5
    ...    --filter-in='Physical Memory' --critical-prct=0.1
    ...    CRITICAL: 'Physical Memory#memory.usage.percent' is 13.62% | 'Physical Memory#memory.usage.percent'=13.62%;;0.1;0;100 'Physical Memory#memory.usage.bytes'=585039872B;;;0;4294377472
