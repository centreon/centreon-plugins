*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::nortel::standard::snmp::plugin


*** Test Cases ***
hardware-4950gts ${tc}
    [Tags]    network    snmp
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=stack
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/4950gts-pwr
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                      expected_result    --
            ...      1     ${EMPTY}                           OK: Number of units: 1 - Stack unit '19KH3850T221' operational state: normal [admin state: enable] - detected: 0 | 'stack.units.count'=1;;;0; '19KH3850T221#stack.unit.detected.seconds'=0s;;;0;
            ...      2     --warning-units-total=0:0          WARNING: Number of units: 1 | 'stack.units.count'=1;0:0;;0; '19KH3850T221#stack.unit.detected.seconds'=0s;;;0;
            ...      3     --critical-units-total=0:0         CRITICAL: Number of units: 1 | 'stack.units.count'=1;;0:0;0; '19KH3850T221#stack.unit.detected.seconds'=0s;;;0;
            ...      4     --warning-unit-detected=1:         WARNING: Stack unit '19KH3850T221' detected: 0 | 'stack.units.count'=1;;;0; '19KH3850T221#stack.unit.detected.seconds'=0s;1:;;0;
            ...      5     --critical-unit-detected=1:        CRITICAL: Stack unit '19KH3850T221' detected: 0 | 'stack.units.count'=1;;;0; '19KH3850T221#stack.unit.detected.seconds'=0s;;1:;0;

