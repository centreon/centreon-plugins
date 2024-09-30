*** Settings ***
Documentation       Check Stormshield equipment

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::stormshield::snmp::plugin


*** Test Cases ***
hardware ${tc}
    [Tags]    network    Stormshield
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/stormshield/snmp/stormshield-fake
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                expected_result    --
            ...      1     --critical='temperature,.*,50'                                               CRITICAL: temperature 'cpu1' is 70 celsius | 'cpu1#hardware.temperature.celsius'=70C;;0:50;0; 'cpu2#hardware.temperature.celsius'=30C;;0:50;0; 'cpu3#hardware.temperature.celsius'=0C;;0:50;0; 'hardware.temperature.count'=3;;;;
            ...      2     --threshold-overload='disk,WARNING,missing'                                  OK: All 3 components are ok [3/3 temperatures]. | 'cpu1#hardware.temperature.celsius'=70C;;;0; 'cpu2#hardware.temperature.celsius'=30C;;;0; 'cpu3#hardware.temperature.celsius'=0C;;;0; 'hardware.temperature.count'=3;;;;
            ...      3     --warning='temperature,.*,40'                                                WARNING: temperature 'cpu1' is 70 celsius | 'cpu1#hardware.temperature.celsius'=70C;0:40;;0; 'cpu2#hardware.temperature.celsius'=30C;0:40;;0; 'cpu3#hardware.temperature.celsius'=0C;0:40;;0; 'hardware.temperature.count'=3;;;;
            ...      4     --warning='temperature,cpu1,60'                                              WARNING: temperature 'cpu1' is 70 celsius | 'cpu1#hardware.temperature.celsius'=70C;0:60;;0; 'cpu2#hardware.temperature.celsius'=30C;;;0; 'cpu3#hardware.temperature.celsius'=0C;;;0; 'hardware.temperature.count'=3;;;;
            ...      5     --critical='temperature,cpu1,75'                                             OK: All 3 components are ok [3/3 temperatures]. | 'cpu1#hardware.temperature.celsius'=70C;;0:75;0; 'cpu2#hardware.temperature.celsius'=30C;;;0; 'cpu3#hardware.temperature.celsius'=0C;;;0; 'hardware.temperature.count'=3;;;;
            ...      6     --warning='temperature,cpu1,300' --critical='temperature,cpu1,17'            CRITICAL: temperature 'cpu1' is 70 celsius | 'cpu1#hardware.temperature.celsius'=70C;0:300;0:17;0; 'cpu2#hardware.temperature.celsius'=30C;;;0; 'cpu3#hardware.temperature.celsius'=0C;;;0; 'hardware.temperature.count'=3;;;;
