*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=os::f5os::snmp::plugin

*** Test Cases ***
hardware ${tc}
    [Tags]    os    f5os    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/f5os/snmp/f5os
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                    expected_result    --
            ...      1     ${EMPTY}                                                                         OK: Current temperature: 31.6 C, average: 32.1 C, minimum: 31.2 C, maximum: 33.8 C - All fans are ok | 'temperature.current.celsius'=31.6C;;;; 'temperature.average.1h.celsius'=32.1C;;;; 'temperature.min.1h.celsius'=31.2C;;;; 'temperature#temperature.max.1h.celsius'=33.8C;;;; '1#fantray.fanspeed.rpm'=15482rpm;;;0; '2#fantray.fanspeed.rpm'=17323rpm;;;0; '3#fantray.fanspeed.rpm'=17121rpm;;;0; '4#fantray.fanspeed.rpm'=17512rpm;;;0; '5#fantray.fanspeed.rpm'=17695rpm;;;0; '6#fantray.fanspeed.rpm'=13543rpm;;;0; '7#fantray.fanspeed.rpm'=16678rpm;;;0; '8#fantray.fanspeed.rpm'=17843rpm;;;0;
            ...      2     --filter-counters=min-temperature                                                OK: minimum: 31.2 C | 'temperature.min.1h.celsius'=31.2C;;;;  
            ...      3     --include-id=2                                                                   OK: Current temperature: 31.6 C, average: 32.1 C, minimum: 31.2 C, maximum: 33.8 C - fan '2' speed is 17323 rpm | 'temperature.current.celsius'=31.6C;;;; 'temperature.average.1h.celsius'=32.1C;;;; 'temperature.min.1h.celsius'=31.2C;;;; 'temperature#temperature.max.1h.celsius'=33.8C;;;; '2#fantray.fanspeed.rpm'=17323rpm;;;0;
            ...      4     --warning-current-temperature=10                                                 WARNING: Current temperature: 31.6 C | 'temperature.current.celsius'=31.6C;0:10;;; 'temperature.average.1h.celsius'=32.1C;;;; 'temperature.min.1h.celsius'=31.2C;;;; 'temperature#temperature.max.1h.celsius'=33.8C;;;; '1#fantray.fanspeed.rpm'=15482rpm;;;0; '2#fantray.fanspeed.rpm'=17323rpm;;;0; '3#fantray.fanspeed.rpm'=17121rpm;;;0; '4#fantray.fanspeed.rpm'=17512rpm;;;0; '5#fantray.fanspeed.rpm'=17695rpm;;;0; '6#fantray.fanspeed.rpm'=13543rpm;;;0; '7#fantray.fanspeed.rpm'=16678rpm;;;0; '8#fantray.fanspeed.rpm'=17843rpm;;;0;
            ...      5     --warning-average-temperature=10                                                 WARNING: average: 32.1 C | 'temperature.current.celsius'=31.6C;;;; 'temperature.average.1h.celsius'=32.1C;0:10;;; 'temperature.min.1h.celsius'=31.2C;;;; 'temperature#temperature.max.1h.celsius'=33.8C;;;; '1#fantray.fanspeed.rpm'=15482rpm;;;0; '2#fantray.fanspeed.rpm'=17323rpm;;;0; '3#fantray.fanspeed.rpm'=17121rpm;;;0; '4#fantray.fanspeed.rpm'=17512rpm;;;0; '5#fantray.fanspeed.rpm'=17695rpm;;;0; '6#fantray.fanspeed.rpm'=13543rpm;;;0; '7#fantray.fanspeed.rpm'=16678rpm;;;0; '8#fantray.fanspeed.rpm'=17843rpm;;;0;
            ...      6     --critical-min-temperature=20                                                    CRITICAL: minimum: 31.2 C | 'temperature.current.celsius'=31.6C;;;; 'temperature.average.1h.celsius'=32.1C;;;; 'temperature.min.1h.celsius'=31.2C;;0:20;; 'temperature#temperature.max.1h.celsius'=33.8C;;;; '1#fantray.fanspeed.rpm'=15482rpm;;;0; '2#fantray.fanspeed.rpm'=17323rpm;;;0; '3#fantray.fanspeed.rpm'=17121rpm;;;0; '4#fantray.fanspeed.rpm'=17512rpm;;;0; '5#fantray.fanspeed.rpm'=17695rpm;;;0; '6#fantray.fanspeed.rpm'=13543rpm;;;0; '7#fantray.fanspeed.rpm'=16678rpm;;;0; '8#fantray.fanspeed.rpm'=17843rpm;;;0;
            ...      7     --critical-max-temperature=10                                                    CRITICAL: maximum: 33.8 C | 'temperature.current.celsius'=31.6C;;;; 'temperature.average.1h.celsius'=32.1C;;;; 'temperature.min.1h.celsius'=31.2C;;;; 'temperature#temperature.max.1h.celsius'=33.8C;;0:10;; '1#fantray.fanspeed.rpm'=15482rpm;;;0; '2#fantray.fanspeed.rpm'=17323rpm;;;0; '3#fantray.fanspeed.rpm'=17121rpm;;;0; '4#fantray.fanspeed.rpm'=17512rpm;;;0; '5#fantray.fanspeed.rpm'=17695rpm;;;0; '6#fantray.fanspeed.rpm'=13543rpm;;;0; '7#fantray.fanspeed.rpm'=16678rpm;;;0; '8#fantray.fanspeed.rpm'=17843rpm;;;0;
            ...      8     --component=temperature                                                          OK: Current temperature: 31.6 C, average: 32.1 C, minimum: 31.2 C, maximum: 33.8 C | 'temperature.current.celsius'=31.6C;;;; 'temperature.average.1h.celsius'=32.1C;;;; 'temperature.min.1h.celsius'=31.2C;;;; 'temperature#temperature.max.1h.celsius'=33.8C;;;;
