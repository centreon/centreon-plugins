*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
list-storages ${tc}
    [Tags]    os    Windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=list-storages
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                   expected_result    --
            ...      1     --display-transform-src='dev'                                                                   List storage: 'Serial Number 5a987053' [size = 63720910848B] [id = 1] Skipping storage 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675': no type or no matching filter type Skipping storage 'Virtual Memory': no type or no matching filter type Skipping storage 'Physical Memory': no type or no matching filter type
            ...      2     -display-transform-dst='run'                                                                    List storage: 'Serial Number 5a987053' [size = 63720910848B] [id = 1] Skipping storage 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675': no type or no matching filter type Skipping storage 'Virtual Memory': no type or no matching filter type Skipping storage 'Physical Memory': no type or no matching filter type
            ...      3     --filter-storage-type='^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$'             List storage: 'Serial Number 5a987053' [size = 63720910848B] [id = 1] Skipping storage 'D:\\\\ Label:SSS_X64FRE_FR-FR_DV9 Serial Number cf70e675': no type or no matching filter type Skipping storage 'Virtual Memory': no type or no matching filter type Skipping storage 'Physical Memory': no type or no matching filter type
