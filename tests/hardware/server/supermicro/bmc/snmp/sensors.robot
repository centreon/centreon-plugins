*** Settings ***
Documentation       sensors

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}    --plugin=hardware::server::supermicro::bmc::snmp::plugin

*** Test Cases ***
sensors ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=hardware::server::supermicro::bmc::snmp::plugin
    ...    --mode=sensors
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=hardware/server/supermicro/bmc/snmp/impi
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                expected_result    --
            ...      1     --warning='sensor,.*,30'     OK: All 0 components are ok [].
            ...      2     --critical='sensor,.*,40'    OK: All 0 components are ok [].
            ...      3     --filter=sensor,fan          OK: All 0 components are ok [].
            ...      4     --no-component               CRITICAL: No components are checked.
