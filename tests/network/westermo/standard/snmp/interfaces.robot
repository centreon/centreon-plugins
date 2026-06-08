*** Settings ***
Documentation       network::westermo::standard::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::westermo::standard::snmp::plugin
...         --mode=interfaces
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/westermo/standard/snmp/westermo_interfaces
...         --add-traffic
...         --add-status


*** Test Cases ***
Interfaces ${tc}
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
    ...    OK: All interfaces are ok
    ...    2
    ...    ${EMPTY}
    ...    OK: All interfaces are ok | 'DSL 2#interface.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSL 2#interface.traffic.out.bitspersecond'=0.00b/s;;;0; 'vlan1#interface.traffic.in.bitspersecond'=0.00b/s;;;0; 'vlan1#interface.traffic.out.bitspersecond'=0.00b/s;;;0; 'vlan16#interface.traffic.in.bitspersecond'=0.00b/s;;;0; 'vlan16#interface.traffic.out.bitspersecond'=0.00b/s;;;0; 'vlan17#interface.traffic.in.bitspersecond'=0.00b/s;;;0; 'vlan17#interface.traffic.out.bitspersecond'=0.00b/s;;;0; 'vlan18#interface.traffic.in.bitspersecond'=0.00b/s;;;0; 'vlan18#interface.traffic.out.bitspersecond'=0.00b/s;;;0; 'vlan29#interface.traffic.in.bitspersecond'=0.00b/s;;;0; 'vlan29#interface.traffic.out.bitspersecond'=0.00b/s;;;0;
