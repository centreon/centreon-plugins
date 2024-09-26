*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
list-storages ${tc}
    [Tags]    os    linux
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
            ...      1     --verbose                                                                                       List storage:${SPACE} 'C:\ Label:  Serial Number 5a987053' [size = 63720910848B] [id = 1] ${SPACE}Skipping storage 'D:\ Label:SSS_X64FRE_FR-FR_DV9  Serial Number cf70e675': no type or no matching filter type ${SPACE}Skipping storage 'Virtual Memory': no type or no matching filter type ${SPACE}Skipping storage 'Physical Memory': no type or no matching filter type
            ...      2     --display-transform-src='dev'                                                                   List storage:${SPACE} 'C:\ Label:  Serial Number 5a987053' [size = 63720910848B] [id = 1] ${SPACE}Skipping storage 'D:\ Label:SSS_X64FRE_FR-FR_DV9  Serial Number cf70e675': no type or no matching filter type ${SPACE}Skipping storage 'Virtual Memory': no type or no matching filter type ${SPACE}Skipping storage 'Physical Memory': no type or no matching filter type
            ...      3     --display-transform-dst='run'                                                                   List storage:${SPACE} 'C:\ Label:  Serial Number 5a987053' [size = 63720910848B] [id = 1] ${SPACE}Skipping storage 'D:\ Label:SSS_X64FRE_FR-FR_DV9  Serial Number cf70e675': no type or no matching filter type ${SPACE}Skipping storage 'Virtual Memory': no type or no matching filter type ${SPACE}Skipping storage 'Physical Memory': no type or no matching filter type
            ...      4     --filter-storage-type=''                                                                        List storage:${SPACE} 'C:\ Label:  Serial Number 5a987053' [size = 63720910848B] [id = 1] ${SPACE}'D:\ Label:SSS_X64FRE_FR-FR_DV9  Serial Number cf70e675' [size = 5566558208B] [id = 2] ${SPACE}'Virtual Memory' [size = 5099683840B] [id = 3] ${SPACE}'Physical Memory' [size = 4294377472B] [id = 4]
            ...      5     --filter-storage-type='^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$'             List storage:${SPACE} 'C:\ Label:  Serial Number 5a987053' [size = 63720910848B] [id = 1] ${SPACE}Skipping storage 'D:\ Label:SSS_X64FRE_FR-FR_DV9  Serial Number cf70e675': no type or no matching filter type ${SPACE}Skipping storage 'Virtual Memory': no type or no matching filter type ${SPACE}Skipping storage 'Physical Memory': no type or no matching filter type