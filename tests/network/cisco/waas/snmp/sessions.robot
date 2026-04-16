*** Settings ***
Documentation       network::cisco::waas::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::waas::snmp::plugin


*** Test Cases ***
Sessions ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=sessions
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/waas/snmp/sessions
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                            expected_result    --
            ...      1     ${EMPTY}                                                 OK: Passthrough_connections: 2 Optimized_connections: 3 / 5 licences | 'Passthrough_connections'=2con;;;; 'Optimized_connections'=3con;0:3;0:3.5;0;5
            ...      2     --warning=1                                              WARNING: Passthrough_connections: 2 Optimized_connections: 3 / 5 licences | 'Passthrough_connections'=2con;;;; 'Optimized_connections'=3con;0:0.05;0:3.5;0;5
            ...      3     --critical=1                                             CRITICAL: Passthrough_connections: 2 Optimized_connections: 3 / 5 licences | 'Passthrough_connections'=2con;;;; 'Optimized_connections'=3con;0:3;0:0.05;0;5
            ...      4     --warning=90:                                            WARNING: Passthrough_connections: 2 Optimized_connections: 3 / 5 licences | 'Passthrough_connections'=2con;;;; 'Optimized_connections'=3con;4.5;0:3.5;0;5
            ...      5     --critical=90:                                           CRITICAL: Passthrough_connections: 2 Optimized_connections: 3 / 5 licences | 'Passthrough_connections'=2con;;;; 'Optimized_connections'=3con;0:3;4.5;0;5
            ...      6     --warning=1:2                                            WARNING: Passthrough_connections: 2 Optimized_connections: 3 / 5 licences | 'Passthrough_connections'=2con;;;; 'Optimized_connections'=3con;0.05:0.1;0:3.5;0;5
            ...      7     --critical=1:2                                           CRITICAL: Passthrough_connections: 2 Optimized_connections: 3 / 5 licences | 'Passthrough_connections'=2con;;;; 'Optimized_connections'=3con;0:3;0.05:0.1;0;5
            ...      8     --warning=@50:80                                         WARNING: Passthrough_connections: 2 Optimized_connections: 3 / 5 licences | 'Passthrough_connections'=2con;;;; 'Optimized_connections'=3con;@2.5:4;0:3.5;0;5
            ...      9     --critical=@50:80                                        CRITICAL: Passthrough_connections: 2 Optimized_connections: 3 / 5 licences | 'Passthrough_connections'=2con;;;; 'Optimized_connections'=3con;0:3;@2.5:4;0;5
