*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
hardware ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                      expected_result    --
            ...      1     ${EMPTY}                                                           OK: All 7 components are ok [4/4 fans, 2/2 psus, 1/1 temperatures]. | '1#hardware.fan.speed.rpm'=0rpm;;;0; '2#hardware.fan.speed.rpm'=0rpm;;;0; '3#hardware.fan.speed.rpm'=0rpm;;;0; '4#hardware.fan.speed.rpm'=0rpm;;;0; '1#hardware.temperature.celsius'=18.00C;;;; 'hardware.fan.count'=4;;;; 'hardware.psu.count'=2;;;; 'hardware.temperature.count'=1;;;;
            ...      2     --filter='.*' --no-component=CRITICAL                              CRITICAL: No components are checked.
            ...      3     --component='temperature'                                          OK: All 1 components are ok [1/1 temperatures]. | '1#hardware.temperature.celsius'=18.00C;;;; 'hardware.temperature.count'=1;;;;
            ...      4     --threshold-overload='fan,CRITICAL,^(?!(good)$)'                   OK: All 7 components are ok [4/4 fans, 2/2 psus, 1/1 temperatures]. | '1#hardware.fan.speed.rpm'=0rpm;;;0; '2#hardware.fan.speed.rpm'=0rpm;;;0; '3#hardware.fan.speed.rpm'=0rpm;;;0; '4#hardware.fan.speed.rpm'=0rpm;;;0; '1#hardware.temperature.celsius'=18.00C;;;; 'hardware.fan.count'=4;;;; 'hardware.psu.count'=2;;;; 'hardware.temperature.count'=1;;;;
            ...      5     --warning='temperature,.*,30'                                      OK: All 7 components are ok [4/4 fans, 2/2 psus, 1/1 temperatures]. | '1#hardware.fan.speed.rpm'=0rpm;;;0; '2#hardware.fan.speed.rpm'=0rpm;;;0; '3#hardware.fan.speed.rpm'=0rpm;;;0; '4#hardware.fan.speed.rpm'=0rpm;;;0; '1#hardware.temperature.celsius'=18.00C;0:30;;; 'hardware.fan.count'=4;;;; 'hardware.psu.count'=2;;;; 'hardware.temperature.count'=1;;;;
            ...      6     --critical='temperature,.*,40'                                     OK: All 7 components are ok [4/4 fans, 2/2 psus, 1/1 temperatures]. | '1#hardware.fan.speed.rpm'=0rpm;;;0; '2#hardware.fan.speed.rpm'=0rpm;;;0; '3#hardware.fan.speed.rpm'=0rpm;;;0; '4#hardware.fan.speed.rpm'=0rpm;;;0; '1#hardware.temperature.celsius'=18.00C;;0:40;; 'hardware.fan.count'=4;;;; 'hardware.psu.count'=2;;;; 'hardware.temperature.count'=1;;;;