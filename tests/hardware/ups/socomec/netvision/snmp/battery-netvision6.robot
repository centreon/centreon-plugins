*** Settings ***
Documentation       Hardware UPS Socomec Netvision SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=hardware::ups::socomec::netvision::snmp::plugin


*** Test Cases ***
Battery ${tc}
    [Tags]    hardware    ups    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=battery
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=hardware/ups/socomec/netvision/snmp/netvision6
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     ${EMPTY}                                                                                                 OK: battery status is normal - charge remaining: 100% (10 minutes remaining) | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=10;;;0; 'battery.current.ampere'=2.3A;;;0; 'battery.voltage.volt'=534V;;;; 'battery.temperature.celsius'=2.2C;;;; 'battery.temperatureambient.celsius'=19C;;;;
            ...      2     --warning-charge-remaining=50 --critical-charge-remaining=100                                           WARNING: charge remaining: 100% (10 minutes remaining) | 'battery.charge.remaining.percent'=100%;0:50;0:100;0;100 'battery.charge.remaining.minutes'=10;;;0; 'battery.current.ampere'=2.3A;;;0; 'battery.voltage.volt'=534V;;;; 'battery.temperature.celsius'=2.2C;;;; 'battery.temperatureambient.celsius'=19C;;;;
            ...      3     --warning-charge-remaining-minutes=10 --critical-charge-remaining-minutes=5                             CRITICAL: minutes remaining: 10 | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=10;0:10;0:5;0; 'battery.current.ampere'=2.3A;;;0; 'battery.voltage.volt'=534V;;;; 'battery.temperature.celsius'=2.2C;;;; 'battery.temperatureambient.celsius'=19C;;;;
            ...      4     --warning-voltage=520 --critical-voltage=550                                                            WARNING: voltage: 534 V | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=10;;;0; 'battery.current.ampere'=2.3A;;;0; 'battery.voltage.volt'=534V;0:520;0:550;; 'battery.temperature.celsius'=2.2C;;;; 'battery.temperatureambient.celsius'=19C;;;;
            ...      5     --warning-temperature=5 --critical-temperature=10                                                       OK: battery status is normal - charge remaining: 100% (10 minutes remaining) | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=10;;;0; 'battery.current.ampere'=2.3A;;;0; 'battery.voltage.volt'=534V;;;; 'battery.temperature.celsius'=2.2C;0:5;0:10;; 'battery.temperatureambient.celsius'=19C;;;;
            ...      6     --warning-temperatureambient=3 --critical-temperatureambient=10                                         CRITICAL: temperatureambient: 19 C | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=10;;;0; 'battery.current.ampere'=2.3A;;;0; 'battery.voltage.volt'=534V;;;; 'battery.temperature.celsius'=2.2C;;;; 'battery.temperatureambient.celsius'=19C;0:3;0:10;;
            ...      7     --unknown-status='\\\%{status} =~ /normal/i'                                                            UNKNOWN: battery status is normal | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=10;;;0; 'battery.current.ampere'=2.3A;;;0; 'battery.voltage.volt'=534V;;;; 'battery.temperature.celsius'=2.2C;;;; 'battery.temperatureambient.celsius'=19C;;;;
            ...      8     --warning-status='\\\%{status} =~ /normal/i'                                                            WARNING: battery status is normal | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=10;;;0; 'battery.current.ampere'=2.3A;;;0; 'battery.voltage.volt'=534V;;;; 'battery.temperature.celsius'=2.2C;;;; 'battery.temperatureambient.celsius'=19C;;;;
            ...      9     --critical-status='\\\%{status} =~ /normal/i'                                                           CRITICAL: battery status is normal | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=10;;;0; 'battery.current.ampere'=2.3A;;;0; 'battery.voltage.volt'=534V;;;; 'battery.temperature.celsius'=2.2C;;;; 'battery.temperatureambient.celsius'=19C;;;;
            ...      10    --warning-current=0 --critical-current=100                                                              WARNING: current: 2.3 A | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=10;;;0; 'battery.current.ampere'=2.3A;0:0;0:100;0; 'battery.voltage.volt'=534V;;;; 'battery.temperature.celsius'=2.2C;;;; 'battery.temperatureambient.celsius'=19C;;;;
