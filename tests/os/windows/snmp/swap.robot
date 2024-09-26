*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
swap ${tc}
    [Tags]    os    linux
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

    Examples:        tc    extra_options                expected_result    --
            ...      1     --real-swap=0                OK: Swap Total: 3.75 GB Used: 1.90 GB (50.61%) Free: 1.85 GB (49.39%) | 'used'=2038861824B;;;0;4028719104 
            ...      2     --warning='80'               OK: Swap Total: 3.75 GB Used: 1.90 GB (50.61%) Free: 1.85 GB (49.39%) | 'used'=2038861824B;0:3222975283;;0;4028719104
            ...      3     --critical='90'              OK: Swap Total: 3.75 GB Used: 1.90 GB (50.61%) Free: 1.85 GB (49.39%) | 'used'=2038861824B;;0:3625847193;0;4028719104
            ...      4     --critical='0'               CRITICAL: Swap Total: 3.75 GB Used: 1.90 GB (50.61%) Free: 1.85 GB (49.39%) | 'used'=2038861824B;;0:0;0;4028719104
            ...      5     --warning='0'                WARNING: Swap Total: 3.75 GB Used: 1.90 GB (50.61%) Free: 1.85 GB (49.39%) | 'used'=2038861824B;0:0;;0;4028719104
