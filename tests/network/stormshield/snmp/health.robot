*** Settings ***
Documentation       Check Stormshield health equipment

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::stormshield::snmp::plugin


*** Test Cases ***
hardware ${tc}
    [Tags]    network    stormshield
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=health
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/stormshield/snmp/sn910
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --filter-serial='notfoundSerial'
    ...    UNKNOWN: No firewall found with accepted serial.
    ...    2
    ...    --critical-service-status="" --warning-service-status=""
    ...    OK: All firewalls are ok
    ...    3
    ...    --verbose
    ...    CRITICAL: 2 problem(s) detected \ncritical: firewall 'Firewall_1_serial_number' service 'cpu' health: Major\nwarning: firewall 'Firewall_2_serial_number' service 'NTP' health: Minor
    ...    4
    ...    --warning-service-status=""
    ...    CRITICAL: 1 problem(s) detected
    ...    5
    ...    --critical-service-status=""
    ...    WARNING: 1 problem(s) detected
