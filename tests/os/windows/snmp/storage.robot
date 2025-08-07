*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
storage ${tc}
    [Tags]    os    Windows
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
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                    expected_result    --
            ...      1     --filter-storage-type            OK: All storages are ok | 'count'=4;;;0; 'used_Serial Number 5a987053'=31299354624B;;;0;63720910848 'used_D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675'=5566558208B;;;0;5566558208 'used_Virtual Memory'=493027328B;;;0;5099683840 'used_Physical Memory'=585039872B;;;0;4294377472
            ...      2     --filter-duplicate               OK: Storage 'Serial Number 5a987053' Usage Total: 59.34 GB Used: 29.15 GB (49.12%) Free: 30.19 GB (50.88%) | 'count'=1;;;0; 'used'=31299354624B;;;0;63720910848
