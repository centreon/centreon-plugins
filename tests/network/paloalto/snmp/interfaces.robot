*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::paloalto::snmp::plugin


*** Test Cases ***
interfaces - traffic ${tc}
    [Tags]    network    paloalto    snmp_standard    interfaces

    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=${snmp_community}
    ...    --snmp-timeout=1
    ...    --add-traffic
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:        tc    snmp_community                     extra_options    expected_result    --
            ...      1     network/paloalto/snmp/paloalto1    ${EMPTY}         
            ...      OK: Interface 'ethernet1' Traffic In : Buffer creation, Traffic Out : Buffer creation
            ...      2     network/paloalto/snmp/paloalto1    ${EMPTY}
            ...      OK: Interface 'ethernet1' Traffic In : 0.00b/s \\\\(0.00%\\\\), Traffic Out : 0.00b/s \\\\(0.00%\\\\) \\\\| 'traffic_in'=0.00b/s;;;0;1000000000 'traffic_out'=0.00b/s;;;0;1000000000
            ...      3     network/paloalto/snmp/paloalto2    ${EMPTY}
            ...      OK: Interface 'ethernet1' Traffic In : \\\\d+.\\\\d+ [KMG]?b/s \\\\(\\\\d+.\\\\d+%\\\\), Traffic Out : \\\\d+.\\\\d+ [KMG]?b/s \\\\(\\\\d+.\\\\d+%\\\\) | 'traffic_in'=\\\\d+.\\\\d+b/s;;;0;2000000000 'traffic_out'=\\\\d+.\\\\d+b/s;;;0;2000000000
            ...      4     network/paloalto/snmp/paloalto1    ${EMPTY}
            ...      OK: Interface 'ethernet1' Traffic In : 0.00b/s \\\\(0.00%\\\\), Traffic Out : 0.00b/s \\\\(0.00%\\\\) \\\\| 'traffic_in'=0.00b/s;;;0;1000000000 'traffic_out'=0.00b/s;;;0;1000000000

interfaces - errors ${tc}
    [Tags]    network    paloalto    snmp_standard    interfaces

    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=${snmp_community}
    ...    --snmp-timeout=1
    ...    --add-errors
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    snmp_community                     extra_options    expected_result    --
            ...      1     network/paloalto/snmp/paloalto1    ${EMPTY}
            ...      OK: Interface 'ethernet1' Packets In Discard : Buffer creation, Packets In Error : Buffer creation, Packets Out Discard : Buffer creation, Packets Out Error : Buffer creation
            ...      2     network/paloalto/snmp/paloalto1    ${EMPTY}
            ...      OK: Interface 'ethernet1' Packets In Discard : 0.00% (0 on 0), Packets Out Discard : 0.00% (0 on 0), Packets Out Error : 0.00% (0 on 0) | 'packets_discard_in'=0.00%;;;0;100 'packets_discard_out'=0.00%;;;0;100 'packets_error_out'=0.00%;;;0;100
            ...      3     network/paloalto/snmp/paloalto2    ${EMPTY}
            ...      OK: Interface 'ethernet1' Packets In Discard : 100.00% (35000000 on 35000000), Packets Out Discard : 71.50% (7150000 on 10000000), Packets Out Error : 0.35% (35000 on 10000000) | 'packets_discard_in'=100.00%;;;0;100 'packets_discard_out'=71.50%;;;0;100 'packets_error_out'=0.35%;;;0;100
            ...      4     network/paloalto/snmp/paloalto1    ${EMPTY}
            ...      OK: Interface 'ethernet1' Packets In Discard : 99.77% (15000000 on 15034968), Packets In Error : Buffer creation, Packets Out Discard : 3.50% (350000 on 10000000), Packets Out Error : 0.45% (45000 on 10000000) | 'packets_discard_in'=99.77%;;;0;100 'packets_discard_out'=3.50%;;;0;100 'packets_error_out'=0.45%;;;0;100
