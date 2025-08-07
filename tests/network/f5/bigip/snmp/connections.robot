*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
connections ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=connections
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                           expected_result    --
            ...      1     ${EMPTY}                                                OK: Current client connections : 5395, Current client SSL connections : 0, client-ssl-tps : Buffer creation, Current server connections: 5242, Current server SSL connections : 4574 | 'connections.client.current.count'=5395;;;0; 'connections.client.ssl.current.count'=0;;;0; 'connections.server.current.count'=5242;;;0; 'connections.server.ssl.current.count'=4574;;;0;
            ...      2     --filter-counters='^client-ssl|server-ssl$'             OK: Current client SSL connections : 0, client-ssl-tps : Buffer creation, Current server SSL connections : 4574 | 'connections.client.ssl.current.count'=0;;;0; 'connections.server.ssl.current.count'=4574;;;0;
            ...      3     --warning-client=25                                     WARNING: Current client connections : 5395 | 'connections.client.current.count'=5395;0:25;;0; 'connections.client.ssl.current.count'=0;;;0; 'connections.client.ssl.persecond'=0.00;;;0; 'connections.server.current.count'=5242;;;0; 'connections.server.ssl.current.count'=4574;;;0;
            ...      4     --critical-client=25                                    CRITICAL: Current client connections : 5395 | 'connections.client.current.count'=5395;;0:25;0; 'connections.client.ssl.current.count'=0;;;0; 'connections.client.ssl.persecond'=0.00;;;0; 'connections.server.current.count'=5242;;;0; 'connections.server.ssl.current.count'=4574;;;0;