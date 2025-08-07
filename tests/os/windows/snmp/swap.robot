*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
swap ${tc}
    [Tags]    os    Windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=swap
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                expected_result    --
            ...      1     --real-swap=0                OK: Swap Total: 4.75 GB Used: 470.19 MB (9.67%) Free: 4.29 GB (90.33%) | 'used'=493027328B;;;0;5099683840 
            ...      2     --warning='80'               OK: Swap Total: 4.75 GB Used: 470.19 MB (9.67%) Free: 4.29 GB (90.33%) | 'used'=493027328B;0:4079747072;;0;5099683840
            ...      3     --critical='90'              OK: Swap Total: 4.75 GB Used: 470.19 MB (9.67%) Free: 4.29 GB (90.33%) | 'used'=493027328B;;0:4589715456;0;5099683840
            ...      4     --critical='0'               CRITICAL: Swap Total: 4.75 GB Used: 470.19 MB (9.67%) Free: 4.29 GB (90.33%) | 'used'=493027328B;;0:0;0;5099683840
            ...      5     --warning='0'                WARNING: Swap Total: 4.75 GB Used: 470.19 MB (9.67%) Free: 4.29 GB (90.33%) | 'used'=493027328B;0:0;;0;5099683840
