*** Settings ***
Documentation       Network moxa SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

Test Timeout        120s

*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::moxa::switch::snmp::plugin
...         --mode=interfaces
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/moxa/switch/snmp/interfaces

*** Test Cases ***
network interface ${tc}
    [Tags]    network    moxa    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${arguments}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:    tc    arguments    expected_result    --
        ...    1    --verbose --add-duplex-status    OK: All interfaces are ok Interface 'lo' Status : up (admin: up) (duplex: fullDuplex) Interface 'eth0' Status : up (admin: up) (duplex: halfDuplex) Interface 'eth1' Status : up (admin: up) (duplex: unknown) Interface 'eth2' Status : up (admin: up) (duplex: fullDuplex) Interface 'eth3' Status : up (admin: up) (duplex: fullDuplex)