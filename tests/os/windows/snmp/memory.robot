*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
memory ${tc}
    [Tags]    os    linux
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
    
    Examples:        tc    extra_options                expected_result    --
            ...      1     --verbose                    UNKNOWN: Cannot find physical memory informations. 
            ...      2     --warning-memory=''          UNKNOWN: Cannot find physical memory informations.
            ...      3     --units                      UNKNOWN: Cannot find physical memory informations.
            ...      4     --free                       UNKNOWN: Cannot find physical memory informations.
            ...      5     --critical-memory=''         UNKNOWN: Cannot find physical memory informations.
