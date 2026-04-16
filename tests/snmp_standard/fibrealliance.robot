*** Settings ***
Documentation       snmp_standard fibrealliance
Resource            ${CURDIR}${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=storage::hp::msa2000::snmp::plugin
...         --mode=hardware
...         --snmp-community=snmp_standard/fibrealliance
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}


*** Test Cases ***
Unit ${tc}
    [Tags]    snmp    fibrealliance    unit
    ${command}    Catenate
    ...    ${CMD}
    ...    --component=unit
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extra_options                                          expected_result    --
    ...            1     ${EMPTY}                                               WARNING: Unit 'unknown.SAN-UNIT-2' status is warning | 'hardware.unit.count'=2;;;;
    ...            2     --threshold-overload='unit,OK,^(?!(ok)$)'              OK: All 2 components are ok [2/2 units]. | 'hardware.unit.count'=2;;;;
    ...            3     --threshold-overload='unit,CRITICAL,^(?!(ok)$)'        CRITICAL: Unit 'unknown.SAN-UNIT-2' status is warning | 'hardware.unit.count'=2;;;;
    ...            4     --warning-count-unit=4:                                WARNING: Unit 'unknown.SAN-UNIT-2' status is warning - '2' components 'unit' checked | 'hardware.unit.count'=2;4:;;;
    ...            5     --critical-count-unit=4:                               CRITICAL: '2' components 'unit' checked WARNING: Unit 'unknown.SAN-UNIT-2' status is warning | 'hardware.unit.count'=2;;4:;;

Sensors ${tc}
    [Tags]    snmp    fibrealliance    sensors
    ${command}    Catenate
    ...    ${CMD}
    ...    --component=sensors
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extra_options                                             expected_result    --
    ...            1     ${EMPTY}                                                  WARNING: Sensor 'INFO2' status is warning | 'hardware.sensors.count'=2;;;;
    ...            2     --threshold-overload='sensors,OK,^(?!(ok)$)'              OK: All 2 components are ok [2/2 sensors]. | 'hardware.sensors.count'=2;;;;
    ...            3     --threshold-overload='sensors,CRITICAL,^(?!(ok)$)'        CRITICAL: Sensor 'INFO2' status is warning | 'hardware.sensors.count'=2;;;;
    ...            4     --warning-count-sensors=4:                                WARNING: Sensor 'INFO2' status is warning - '2' components 'sensors' checked | 'hardware.sensors.count'=2;4:;;;
    ...            5     --critical-count-sensors=4:                               CRITICAL: '2' components 'sensors' checked WARNING: Sensor 'INFO2' status is warning | 'hardware.sensors.count'=2;;4:;;

Port ${tc}
    [Tags]    snmp    fibrealliance    port
    ${command}    Catenate
    ...    ${CMD}
    ...    --component=port
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extra_options                                          expected_result    --
    ...            1     ${EMPTY}                                               WARNING: Port 'PORT2' status is warning | 'hardware.port.count'=2;;;;
    ...            2     --threshold-overload='port,OK,^(?!(ok)$)'              OK: All 2 components are ok [2/2 ports]. | 'hardware.port.count'=2;;;;
    ...            3     --threshold-overload='port,CRITICAL,^(?!(ok)$)'        CRITICAL: Port 'PORT1' status is ready - Port 'PORT2' status is warning | 'hardware.port.count'=2;;;;
    ...            4     --warning-count-port=4:                                WARNING: Port 'PORT2' status is warning - '2' components 'port' checked | 'hardware.port.count'=2;4:;;;
    ...            5     --critical-count-port=4:                               CRITICAL: '2' components 'port' checked WARNING: Port 'PORT2' status is warning | 'hardware.port.count'=2;;4:;;
