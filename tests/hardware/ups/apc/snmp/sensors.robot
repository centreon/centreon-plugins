*** Settings ***
Documentation       Check UPS APC Sensors

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}     ${CENTREON_PLUGINS}
    ...    --plugin=hardware::ups::apc::snmp::plugin
    ...    --hostname=${HOSTNAME}
    ...    --mode=sensors
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-timeout=1


*** Test Cases ***
apc galaxy ${tc}
    [Tags]    hardware    ups    apc
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/ups/apc/snmp/ups-apc-galaxy
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:    tc    extra_options                                                         expected_regexp    --
    ...          1     ${EMPTY}                                                              OK: All 1 components are ok [1/1 sensors]. | 'ambient#sensor.ambient.temperature.celsius'=21C;;;; 'hardware.sensor.count'=1;;;;
    ...          2     --critical=temperature,.*,:10                                         CRITICAL: temperature 'ambient' is 21 C | 'ambient#sensor.ambient.temperature.celsius'=21C;;0:10;; 'hardware.sensor.count'=1;;;;
    ...          3     --filter=sensor --no-component=WARNING                                WARNING: No components are checked.

*** Test Cases ***
apc others ${tc}
    [Tags]    hardware    ups    apc
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/ups/apc/snmp/ups-apc-sensors
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:    tc    extra_options                                                         expected_regexp    --
    ...          1     ${EMPTY}                                                              CRITICAL: integrated sensor 'YYYYY Rack 1' status is 'disconnected' WARNING: universal sensor 'Humi XXX' status is 'uioWarning' | 'Temp XXX#sensor.universal.temperature.celsius'=24C;;;; 'Temp XXX#sensor.universal.humidity.percentage'=45%;;;0;100 'Humi XXX#sensor.universal.temperature.celsius'=25C;;;; 'Humi XXX#sensor.universal.humidity.percentage'=44%;;;0;100 'YYYYY Rack 2#sensor.integrated.temperature.celsius'=29C;;;; 'YYYYY Rack 2#sensor.integrated.humidity.percentage'=52%;;;0;100 'hardware.sensor.count'=4;;;; 
    ...	         2     --threshold-overload='sensor,WARNING,disconnected'                    WARNING: universal sensor 'Humi XXX' status is 'uioWarning' - integrated sensor 'YYYYY Rack 1' status is 'disconnected' | 'Temp XXX#sensor.universal.temperature.celsius'=24C;;;; 'Temp XXX#sensor.universal.humidity.percentage'=45%;;;0;100 'Humi XXX#sensor.universal.temperature.celsius'=25C;;;; 'Humi XXX#sensor.universal.humidity.percentage'=44%;;;0;100 'YYYYY Rack 2#sensor.integrated.temperature.celsius'=29C;;;; 'YYYYY Rack 2#sensor.integrated.humidity.percentage'=52%;;;0;100 'hardware.sensor.count'=4;;;;
    ...          3     --filter=sensor,1                                                     WARNING: universal sensor 'Humi XXX' status is 'uioWarning' | 'Humi XXX#sensor.universal.temperature.celsius'=25C;;;; 'Humi XXX#sensor.universal.humidity.percentage'=44%;;;0;100 'YYYYY Rack 2#sensor.integrated.temperature.celsius'=29C;;;; 'YYYYY Rack 2#sensor.integrated.humidity.percentage'=52%;;;0;100 'hardware.sensor.count'=2;;;;
    ...          4     --filter=sensor,1 --critical='temperature,.*,20'                      CRITICAL: universal sensor temperature 'Humi XXX' is 25 C - integrated sensor temperature 'YYYYY Rack 2' is 29 celsius WARNING: universal sensor 'Humi XXX' status is 'uioWarning' | 'Humi XXX#sensor.universal.temperature.celsius'=25C;;0:20;; 'Humi XXX#sensor.universal.humidity.percentage'=44%;;;0;100 'YYYYY Rack 2#sensor.integrated.temperature.celsius'=29C;;0:20;; 'YYYYY Rack 2#sensor.integrated.humidity.percentage'=52%;;;0;100 'hardware.sensor.count'=2;;;;
