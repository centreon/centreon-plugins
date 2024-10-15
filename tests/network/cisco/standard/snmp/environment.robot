*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
environment ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=environment
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --verbose                                                             OK: All 0 components are ok []. Environment type: c37xx Checking fans Checking power supplies Checking temperatures Checking voltages Checking modules Checking physicals Checking sensors
            ...      2     --threshold-overload='fan,CRITICAL,^(?!(up|normal)$)'                 OK: All 0 components are ok [].
            ...      3     --warning='temperature,.*,30'                                         OK: All 0 components are ok [].
            ...      4     --critical='temperature,.*,40'                                        OK: All 0 components are ok [].
