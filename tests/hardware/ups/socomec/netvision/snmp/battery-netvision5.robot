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
    ...    --snmp-community=hardware/ups/socomec/netvision/snmp/netvision5    # netvision5 has no current(A) values
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     ${EMPTY}                                                                                                 OK: battery status is normal - charge remaining: 100% (0 minutes remaining) | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=2C;;;; 'battery.temperatureambient.celsius'=2.2C;;;;
            ...      2     --warning-charge-remaining=50 --critical-charge-remaining=100                                           WARNING: charge remaining: 100% (0 minutes remaining) | 'battery.charge.remaining.percent'=100%;0:50;0:100;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=2C;;;; 'battery.temperatureambient.celsius'=2.2C;;;;
            ...      3     --warning-charge-remaining-minutes=10 --critical-charge-remaining-minutes=0                             OK: battery status is normal - charge remaining: 100% (0 minutes remaining) | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;0:10;0:0;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=2C;;;; 'battery.temperatureambient.celsius'=2.2C;;;;
            ...      4     --warning-voltage=330 --critical-voltage=550                                                            WARNING: voltage: 339.1 V | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;0:330;0:550;; 'battery.temperature.celsius'=2C;;;; 'battery.temperatureambient.celsius'=2.2C;;;;
            ...      5     --warning-temperature=0 --critical-temperature=10                                                       WARNING: temperature: 2 C | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=2C;0:0;0:10;; 'battery.temperatureambient.celsius'=2.2C;;;;
            ...      6     --warning-temperatureambient=3 --critical-temperatureambient=1                                          CRITICAL: temperatureambient: 2.2 C | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=2C;;;; 'battery.temperatureambient.celsius'=2.2C;0:3;0:1;;
            ...      7     --unknown-status='\\\%{status} =~ /normal/i'                                                            UNKNOWN: battery status is normal | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=2C;;;; 'battery.temperatureambient.celsius'=2.2C;;;;
            ...      8     --warning-status='\\\%{status} =~ /normal/i'                                                            WARNING: battery status is normal | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=2C;;;; 'battery.temperatureambient.celsius'=2.2C;;;;
            ...      9     --critical-status='\\\%{status} =~ /normal/i'                                                           CRITICAL: battery status is normal | 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=0;;;0; 'battery.voltage.volt'=339.1V;;;; 'battery.temperature.celsius'=2C;;;; 'battery.temperatureambient.celsius'=2.2C;;;;
