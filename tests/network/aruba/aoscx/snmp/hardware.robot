*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::aruba::aoscx::snmp::plugin

*** Test Cases ***
hardware ${tc}
    [Tags]    network    aruba
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/aruba/aoscx/snmp/slim_aoscx-spanning-tree
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     ${EMPTY}                                                                                                OK: All 7 components are ok [1/1 psu, 6/6 temperatures]. | 'Anonymized 145#hardware.temperature.celsius'=60.00C;;;; 'Anonymized 096#hardware.temperature.celsius'=58.00C;;;; 'Anonymized 138#hardware.temperature.celsius'=20.50C;;;; 'Anonymized 186#hardware.temperature.celsius'=63.50C;;;; 'Anonymized 159#hardware.temperature.celsius'=63.25C;;;; 'Anonymized 101#hardware.temperature.celsius'=63.75C;;;; 'hardware.psu.count'=1;;;; 'hardware.temperature.count'=6;;;;
            ...      2     --component='.*'                                                                                        OK: All 7 components are ok [1/1 psu, 6/6 temperatures]. | 'Anonymized 145#hardware.temperature.celsius'=60.00C;;;; 'Anonymized 096#hardware.temperature.celsius'=58.00C;;;; 'Anonymized 138#hardware.temperature.celsius'=20.50C;;;; 'Anonymized 186#hardware.temperature.celsius'=63.50C;;;; 'Anonymized 159#hardware.temperature.celsius'=63.25C;;;; 'Anonymized 101#hardware.temperature.celsius'=63.75C;;;; 'hardware.psu.count'=1;;;; 'hardware.temperature.count'=6;;;;
            ...      3     --filter='psu'                                                                                          OK: All 6 components are ok [6/6 temperatures]. | 'Anonymized 145#hardware.temperature.celsius'=60.00C;;;; 'Anonymized 096#hardware.temperature.celsius'=58.00C;;;; 'Anonymized 138#hardware.temperature.celsius'=20.50C;;;; 'Anonymized 186#hardware.temperature.celsius'=63.50C;;;; 'Anonymized 159#hardware.temperature.celsius'=63.25C;;;; 'Anonymized 101#hardware.temperature.celsius'=63.75C;;;; 'hardware.temperature.count'=6;;;;
            ...      4     --no-component='CRITICAL' --filter='.*'                                                                 CRITICAL: No components are checked.
            ...      5     --threshold-overload='fan,WARNING,string'                                                               OK: All 7 components are ok [1/1 psu, 6/6 temperatures]. | 'Anonymized 145#hardware.temperature.celsius'=60.00C;;;; 'Anonymized 096#hardware.temperature.celsius'=58.00C;;;; 'Anonymized 138#hardware.temperature.celsius'=20.50C;;;; 'Anonymized 186#hardware.temperature.celsius'=63.50C;;;; 'Anonymized 159#hardware.temperature.celsius'=63.25C;;;; 'Anonymized 101#hardware.temperature.celsius'=63.75C;;;; 'hardware.psu.count'=1;;;; 'hardware.temperature.count'=6;;;;
            ...      6     --warning='temperature,.*,30'                                                                           WARNING: temperature 'Anonymized 145' is 60.00 C - temperature 'Anonymized 096' is 58.00 C - temperature 'Anonymized 186' is 63.50 C - temperature 'Anonymized 159' is 63.25 C - temperature 'Anonymized 101' is 63.75 C | 'Anonymized 145#hardware.temperature.celsius'=60.00C;0:30;;; 'Anonymized 096#hardware.temperature.celsius'=58.00C;0:30;;; 'Anonymized 138#hardware.temperature.celsius'=20.50C;0:30;;; 'Anonymized 186#hardware.temperature.celsius'=63.50C;0:30;;; 'Anonymized 159#hardware.temperature.celsius'=63.25C;0:30;;; 'Anonymized 101#hardware.temperature.celsius'=63.75C;0:30;;; 'hardware.psu.count'=1;;;; 'hardware.temperature.count'=6;;;;
            ...      7     --critical='temperature,.*,40'                                                                          CRITICAL: temperature 'Anonymized 145' is 60.00 C - temperature 'Anonymized 096' is 58.00 C - temperature 'Anonymized 186' is 63.50 C - temperature 'Anonymized 159' is 63.25 C - temperature 'Anonymized 101' is 63.75 C | 'Anonymized 145#hardware.temperature.celsius'=60.00C;;0:40;; 'Anonymized 096#hardware.temperature.celsius'=58.00C;;0:40;; 'Anonymized 138#hardware.temperature.celsius'=20.50C;;0:40;; 'Anonymized 186#hardware.temperature.celsius'=63.50C;;0:40;; 'Anonymized 159#hardware.temperature.celsius'=63.25C;;0:40;; 'Anonymized 101#hardware.temperature.celsius'=63.75C;;0:40;; 'hardware.psu.count'=1;;;; 'hardware.temperature.count'=6;;;;
            ...      8     --warning='fan.speed,.*,1000'                                                                           OK: All 7 components are ok [1/1 psu, 6/6 temperatures]. | 'Anonymized 145#hardware.temperature.celsius'=60.00C;;;; 'Anonymized 096#hardware.temperature.celsius'=58.00C;;;; 'Anonymized 138#hardware.temperature.celsius'=20.50C;;;; 'Anonymized 186#hardware.temperature.celsius'=63.50C;;;; 'Anonymized 159#hardware.temperature.celsius'=63.25C;;;; 'Anonymized 101#hardware.temperature.celsius'=63.75C;;;; 'hardware.psu.count'=1;;;; 'hardware.temperature.count'=6;;;;
            ...      9     --critical='fan.speed,.*,2000'                                                                          OK: All 7 components are ok [1/1 psu, 6/6 temperatures]. | 'Anonymized 145#hardware.temperature.celsius'=60.00C;;;; 'Anonymized 096#hardware.temperature.celsius'=58.00C;;;; 'Anonymized 138#hardware.temperature.celsius'=20.50C;;;; 'Anonymized 186#hardware.temperature.celsius'=63.50C;;;; 'Anonymized 159#hardware.temperature.celsius'=63.25C;;;; 'Anonymized 101#hardware.temperature.celsius'=63.75C;;;; 'hardware.psu.count'=1;;;; 'hardware.temperature.count'=6;;;;
