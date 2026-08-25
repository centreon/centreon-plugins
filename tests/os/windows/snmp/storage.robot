*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS}
${CGS_COLLECTIONS}      ${CURDIR}${/}..${/}..${/}..${/}..${/}rust-plugins${/}rs-collections${/}rust-snmp


*** Test Cases ***
storage ${tc}
    [Tags]    os    windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=storage
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
    ...    --filter-storage-type
    ...    OK: All storages are ok | 'count'=4;;;0; 'used_Serial Number 5a987053'=31299354624B;;;0;63720910848 'used_D:\\\\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675'=5566558208B;;;0;5566558208 'used_Virtual Memory'=493027328B;;;0;5099683840 'used_Physical Memory'=585039872B;;;0;4294377472
    ...    2
    ...    --filter-duplicate
    ...    OK: Storage 'Serial Number 5a987053' Usage Total: 59.34 GB Used: 29.15 GB (49.12%) Free: 30.19 GB (50.88%) | 'count'=1;;;0; 'used'=31299354624B;;;0;63720910848

cgs-storage ${tc}
    [Tags]    os    windows    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CGS_COLLECTIONS}${/}storage.json
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
    ...    --filter-out='(Physical|Virtual) Memory'
    ...    All storages are OK | 'Serial Number 5a987053#storage.usage.bytes'=31299354624B;;;0;63720910848 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.bytes'=5566558208B;;;0;5566558208 'Serial Number 5a987053#storage.usage.percent'=49.12%;;;0;100 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.percent'=100%;;;0;100
    ...    2
    ...    --filter-out='(Physical|Virtual) Memory' --warning-bytes=0.1
    ...    WARNING: 'Serial Number 5a987053#storage.usage.bytes' is 31299354624B, 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.bytes' is 5566558208B | 'Serial Number 5a987053#storage.usage.bytes'=31299354624B;0.1;;0;63720910848 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.bytes'=5566558208B;0.1;;0;5566558208 'Serial Number 5a987053#storage.usage.percent'=49.12%;;;0;100 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.percent'=100%;;;0;100
    ...    3
    ...    --filter-out='(Physical|Virtual) Memory' --critical-bytes=0.1
    ...    CRITICAL: 'Serial Number 5a987053#storage.usage.bytes' is 31299354624B, 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.bytes' is 5566558208B | 'Serial Number 5a987053#storage.usage.bytes'=31299354624B;;0.1;0;63720910848 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.bytes'=5566558208B;;0.1;0;5566558208 'Serial Number 5a987053#storage.usage.percent'=49.12%;;;0;100 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.percent'=100%;;;0;100
    ...    4
    ...    --filter-out='(Physical|Virtual) Memory' --warning-prct=0.1
    ...    WARNING: 'Serial Number 5a987053#storage.usage.percent' is 49.12%, 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.percent' is 100% | 'Serial Number 5a987053#storage.usage.bytes'=31299354624B;;;0;63720910848 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.bytes'=5566558208B;;;0;5566558208 'Serial Number 5a987053#storage.usage.percent'=49.12%;0.1;;0;100 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.percent'=100%;0.1;;0;100
    ...    5
    ...    --filter-out='(Physical|Virtual) Memory' --critical-prct=0.1
    ...    CRITICAL: 'Serial Number 5a987053#storage.usage.percent' is 49.12%, 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.percent' is 100% | 'Serial Number 5a987053#storage.usage.bytes'=31299354624B;;;0;63720910848 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.bytes'=5566558208B;;;0;5566558208 'Serial Number 5a987053#storage.usage.percent'=49.12%;;0.1;0;100 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.percent'=100%;;0.1;0;100
    ...    6
    ...    --filter-out='(Physical|Virtual) Memory' --filter-in='D:'
    ...    All storages are OK | 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.bytes'=5566558208B;;;0;5566558208 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675#storage.usage.percent'=100%;;;0;100
