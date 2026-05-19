*** Settings ***
Documentation       network::westermo::standard::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::westermo::standard::snmp::plugin
...         --mode=sensors
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/westermo/standard/snmp/westermo_sensors


*** Test Cases ***
Sensors ${tc}
    [Tags]    network    westermo    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All 4 components are ok [4/4 sensors]. | 'sensor.celsius_Anonymized 176'=50C;;;; 'sensor.truthvalue_Anonymized 250'=1;;;; 'sensor.truthvalue_Anonymized 090'=2;;;; 'sensor.truthvalue_Anonymized 218'=2;;;; 'hardware.sensor.count'=4;;;;
