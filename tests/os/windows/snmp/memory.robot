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
    
    Examples:        tc    extra_options                                              expected_result    --
            ...      1     --verbose                                                  OK: Ram Total: 3.75GB Used: 1.90GB (50.61%) Free: 1.85GB (49.39%) | 'used'=2038861824B;;;0;4028719104 
            ...      2     --warning-memory='80'                                      OK: Ram Total: 3.75GB Used: 1.90GB (50.61%) Free: 1.85GB (49.39%) | 'used'=2038861824B;0:3222975283;;0;4028719104
            ...      3     --units                                                    OK: Ram Total: 3.75GB Used: 1.90GB (50.61%) Free: 1.85GB (49.39%) | 'used'=2038861824B;;;0;4028719104
            ...      4     --free                                                     OK: Ram Total: 3.75GB Used: 1.90GB (50.61%) Free: 1.85GB (49.39%) | 'memory.free.bytes'=1989857280B;;;0;4028719104
            ...      5     --critical-memory='90' --warning-memory='80'               OK: Ram Total: 3.75GB Used: 1.90GB (50.61%) Free: 1.85GB (49.39%) | 'used'=2038861824B;0:3222975283;0:3625847193;0;4028719104
            ...      6     --critical-memory='0'                                      CRITICAL: Ram Total: 3.75GB Used: 1.90GB (50.61%) Free: 1.85GB (49.39%) | 'used'=2038861824B;;0:0;0;4028719104
            ...      7     --warning-memory='0'                                       WARNING: Ram Total: 3.75GB Used: 1.90GB (50.61%) Free: 1.85GB (49.39%) | 'used'=2038861824B;0:0;;0;4028719104
