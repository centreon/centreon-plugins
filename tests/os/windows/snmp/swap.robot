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
swap ${tc}
    [Tags]    os    windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=swap
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --real-swap=0
    ...    OK: Swap Total: 4.75 GB Used: 470.19 MB (9.67%) Free: 4.29 GB (90.33%) | 'used'=493027328B;;;0;5099683840
    ...    2
    ...    --warning='80'
    ...    OK: Swap Total: 4.75 GB Used: 470.19 MB (9.67%) Free: 4.29 GB (90.33%) | 'used'=493027328B;0:4079747072;;0;5099683840
    ...    3
    ...    --critical='90'
    ...    OK: Swap Total: 4.75 GB Used: 470.19 MB (9.67%) Free: 4.29 GB (90.33%) | 'used'=493027328B;;0:4589715456;0;5099683840
    ...    4
    ...    --critical='0'
    ...    CRITICAL: Swap Total: 4.75 GB Used: 470.19 MB (9.67%) Free: 4.29 GB (90.33%) | 'used'=493027328B;;0:0;0;5099683840
    ...    5
    ...    --warning='0'
    ...    WARNING: Swap Total: 4.75 GB Used: 470.19 MB (9.67%) Free: 4.29 GB (90.33%) | 'used'=493027328B;0:0;;0;5099683840

cgs-virtual-memory ${tc}
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
    ...    --filter-in='Virtual Memory'
    ...    OK: 'Virtual Memory#storage.usage.percent' is 9.67%, 'Virtual Memory#storage.usage.bytes' is 493027328B | 'Virtual Memory#storage.usage.percent'=9.67%;;;0;100 'Virtual Memory#storage.usage.bytes'=493027328B;;;0;5099683840
    ...    2
    ...    --filter-in='Virtual Memory' --warning-bytes=0.1
    ...    WARNING: 'Virtual Memory#storage.usage.bytes' is 493027328B | 'Virtual Memory#storage.usage.percent'=9.67%;;;0;100 'Virtual Memory#storage.usage.bytes'=493027328B;0.1;;0;5099683840
    ...    3
    ...    --filter-in='Virtual Memory' --critical-bytes=0.1
    ...    CRITICAL: 'Virtual Memory#storage.usage.bytes' is 493027328B | 'Virtual Memory#storage.usage.percent'=9.67%;;;0;100 'Virtual Memory#storage.usage.bytes'=493027328B;;0.1;0;5099683840
    ...    4
    ...    --filter-in='Virtual Memory' --warning-prct=0.1
    ...    WARNING: 'Virtual Memory#storage.usage.percent' is 9.67% | 'Virtual Memory#storage.usage.percent'=9.67%;0.1;;0;100 'Virtual Memory#storage.usage.bytes'=493027328B;;;0;5099683840
    ...    5
    ...    --filter-in='Virtual Memory' --critical-prct=0.1
    ...    CRITICAL: 'Virtual Memory#storage.usage.percent' is 9.67% | 'Virtual Memory#storage.usage.percent'=9.67%;;0.1;0;100 'Virtual Memory#storage.usage.bytes'=493027328B;;;0;5099683840
