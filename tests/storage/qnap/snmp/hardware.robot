*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=storage::qnap::snmp::plugin
...         --mode=hardware
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=storage/qnap/snmp/qnap


*** Test Cases ***
Hardware ${tc}
    [Tags]    storage    qnap    hardware    
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}


    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                          expected_result    --
            ...      1     ${EMPTY}                                                                               CRITICAL: Raid 'Anonymized 241' status is Anonymized 197. UNKNOWN: Disk '7' - 'Anonymized 109' [Anonymized 058] status is Anonymized 095. - Disk '8' - 'Anonymized 206' [Anonymized 133] status is Anonymized 113. - Disk '9' - 'Anonymized 217' [Anonymized 072] status is Anonymized 004. - Disk '10' - 'Anonymized 174' [Anonymized 195] status is Anonymized 169. - Disk '11' - 'Anonymized 201' [Anonymized 184] status is Anonymized 133. - Disk '12' - 'Anonymized 181' [Anonymized 221] status is Anonymized 161. | '1#hardware.disk.temperature.celsius'=24C;;;; '2#hardware.disk.temperature.celsius'=24C;;;; '3#hardware.disk.temperature.celsius'=24C;;;; '4#hardware.disk.temperature.celsius'=24C;;;; '5#hardware.disk.temperature.celsius'=24C;;;; '6#hardware.disk.temperature.celsius'=24C;;;; '1#hardware.fan.speed.rpm'=6286rpm;;;0; '2#hardware.fan.speed.rpm'=6143rpm;;;0; '3#hardware.fan.speed.rpm'=6196rpm;;;0; '1#hardware.powersupply.fan.speed.rpm'=2040rpm;;;0; '1#hardware.powersupply.temperature.celsius'=27C;;;; '2#hardware.powersupply.fan.speed.rpm'=1980rpm;;;0; '2#hardware.powersupply.temperature.celsius'=28C;;;; '3#hardware.powersupply.fan.speed.rpm'=0rpm;;;0; '3#hardware.powersupply.temperature.celsius'=0C;;;; '4#hardware.powersupply.fan.speed.rpm'=0rpm;;;0; '4#hardware.powersupply.temperature.celsius'=0C;;;; 'hardware.disk.count'=6;;;; 'hardware.fan.count'=3;;;; 'hardware.psu.count'=4;;;; 'hardware.raid.count'=1;;;;
            ...      2     --component='psu'                                                                      OK: All 4 components are ok [4/4 psu]. | '1#hardware.powersupply.fan.speed.rpm'=2040rpm;;;0; '1#hardware.powersupply.temperature.celsius'=27C;;;; '2#hardware.powersupply.fan.speed.rpm'=1980rpm;;;0; '2#hardware.powersupply.temperature.celsius'=28C;;;; '3#hardware.powersupply.fan.speed.rpm'=0rpm;;;0; '3#hardware.powersupply.temperature.celsius'=0C;;;; '4#hardware.powersupply.fan.speed.rpm'=0rpm;;;0; '4#hardware.powersupply.temperature.celsius'=0C;;;; 'hardware.psu.count'=4;;;;
            ...      3     --filter=psu                                                                           CRITICAL: Raid 'Anonymized 241' status is Anonymized 197. UNKNOWN: Disk '7' - 'Anonymized 109' [Anonymized 058] status is Anonymized 095. - Disk '8' - 'Anonymized 206' [Anonymized 133] status is Anonymized 113. - Disk '9' - 'Anonymized 217' [Anonymized 072] status is Anonymized 004. - Disk '10' - 'Anonymized 174' [Anonymized 195] status is Anonymized 169. - Disk '11' - 'Anonymized 201' [Anonymized 184] status is Anonymized 133. - Disk '12' - 'Anonymized 181' [Anonymized 221] status is Anonymized 161. | '1#hardware.disk.temperature.celsius'=24C;;;; '2#hardware.disk.temperature.celsius'=24C;;;; '3#hardware.disk.temperature.celsius'=24C;;;; '4#hardware.disk.temperature.celsius'=24C;;;; '5#hardware.disk.temperature.celsius'=24C;;;; '6#hardware.disk.temperature.celsius'=24C;;;; '1#hardware.fan.speed.rpm'=6286rpm;;;0; '2#hardware.fan.speed.rpm'=6143rpm;;;0; '3#hardware.fan.speed.rpm'=6196rpm;;;0; 'hardware.disk.count'=6;;;; 'hardware.fan.count'=3;;;; 'hardware.raid.count'=1;;;;
            ...      4     --absent-problem=Raid                                                                  CRITICAL: Raid 'Anonymized 241' status is Anonymized 197. UNKNOWN: Disk '7' - 'Anonymized 109' [Anonymized 058] status is Anonymized 095. - Disk '8' - 'Anonymized 206' [Anonymized 133] status is Anonymized 113. - Disk '9' - 'Anonymized 217' [Anonymized 072] status is Anonymized 004. - Disk '10' - 'Anonymized 174' [Anonymized 195] status is Anonymized 169. - Disk '11' - 'Anonymized 201' [Anonymized 184] status is Anonymized 133. - Disk '12' - 'Anonymized 181' [Anonymized 221] status is Anonymized 161. | '1#hardware.disk.temperature.celsius'=24C;;;; '2#hardware.disk.temperature.celsius'=24C;;;; '3#hardware.disk.temperature.celsius'=24C;;;; '4#hardware.disk.temperature.celsius'=24C;;;; '5#hardware.disk.temperature.celsius'=24C;;;; '6#hardware.disk.temperature.celsius'=24C;;;; '1#hardware.fan.speed.rpm'=6286rpm;;;0; '2#hardware.fan.speed.rpm'=6143rpm;;;0; '3#hardware.fan.speed.rpm'=6196rpm;;;0; '1#hardware.powersupply.fan.speed.rpm'=2040rpm;;;0; '1#hardware.powersupply.temperature.celsius'=27C;;;; '2#hardware.powersupply.fan.speed.rpm'=1980rpm;;;0; '2#hardware.powersupply.temperature.celsius'=28C;;;; '3#hardware.powersupply.fan.speed.rpm'=0rpm;;;0; '3#hardware.powersupply.temperature.celsius'=0C;;;; '4#hardware.powersupply.fan.speed.rpm'=0rpm;;;0; '4#hardware.powersupply.temperature.celsius'=0C;;;; 'hardware.disk.count'=6;;;; 'hardware.fan.count'=3;;;; 'hardware.psu.count'=4;;;; 'hardware.raid.count'=1;;;;
            ...      5     --no-component='UNKNOWN' --component='toto'                                            UNKNOWN: Wrong option. Cannot find component 'toto'.
            ...      6     --threshold-overload='fan,OK,^(?!(ready)$)' --component='fan'                          OK: All 3 components are ok [3/3 fans]. | '1#hardware.fan.speed.rpm'=6286rpm;;;0; '2#hardware.fan.speed.rpm'=6143rpm;;;0; '3#hardware.fan.speed.rpm'=6196rpm;;;0; 'hardware.fan.count'=3;;;;
            ...      7     --warning='fan,.*,1500' --component='fan'                                              WARNING: Fan '1' speed is 6286 rpm - Fan '2' speed is 6143 rpm - Fan '3' speed is 6196 rpm | '1#hardware.fan.speed.rpm'=6286rpm;;;0; '2#hardware.fan.speed.rpm'=6143rpm;;;0; '3#hardware.fan.speed.rpm'=6196rpm;;;0; 'hardware.fan.count'=3;;;;
            ...      8     --critical='fan,.*,1500' --component='fan'                                             CRITICAL: Fan '1' speed is 6286 rpm - Fan '2' speed is 6143 rpm - Fan '3' speed is 6196 rpm | '1#hardware.fan.speed.rpm'=6286rpm;;;0; '2#hardware.fan.speed.rpm'=6143rpm;;;0; '3#hardware.fan.speed.rpm'=6196rpm;;;0; 'hardware.fan.count'=3;;;;