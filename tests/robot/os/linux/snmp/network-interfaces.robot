*** Settings ***
Documentation       Network Interfaces

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=os::linux::snmp::plugin
...         --mode=interfaces
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=os/linux/snmp/network-interfaces
...         --statefile-dir=/tmp/cache/

${COND}     ${PERCENT}\{sub\} =~ /exited/ && ${PERCENT}{display} =~ /network/'


*** Test Cases ***
Interfaces by id ${tc}/5
    [Tags]    os    linux    network    interfaces
    ${command}    Catenate
    ...    ${CMD}
    ...    --interface='${filter}'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    filter                    extra_options                 expected_result    --
            ...      1     1                         ${EMPTY}                      OK: Interface 'lo' Status : up (admin: up)
            ...      2     1,3                       --add-traffic                 OK: All interfaces are ok
            ...      3     1,3                       --add-traffic                 OK: All interfaces are ok | 'traffic_in_lo'=0.00b/s;;;0;10000000 'traffic_out_lo'=0.00b/s;;;0;10000000 'traffic_in_eth1'=0.00b/s;;;0;1000000000 'traffic_out_eth1'=0.00b/s;;;0;1000000000
            ...      4     2,3,4                     --add-traffic                 OK: All interfaces are ok
            ...      5     2,3,4                     --add-traffic                 OK: All interfaces are ok | 'traffic_in_eth0'=0.00b/s;;;0;1000000000 'traffic_out_eth0'=0.00b/s;;;0;1000000000 'traffic_in_eth1'=0.00b/s;;;0;1000000000 'traffic_out_eth1'=0.00b/s;;;0;1000000000 'traffic_in_eth2'=0.00b/s;;;0;1000000000 'traffic_out_eth2'=0.00b/s;;;0;1000000000
# theese test are linked together. The test 2 create the cache file in /tmp/, and the test 3 use this cache file
# to calculate traffic throughput by second.

Interfaces by id regexp ${tc}/6
    [Tags]    os    linux    network    interfaces
    ${command}    Catenate
    ...    ${CMD}
    ...    --interface='${filter}'
    ...    --regex-id
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    filter         extra_options      expected_result    --
            ...      1     ^1$            ${EMPTY}           OK: Interface 'lo' Status : up (admin: up)
            ...      2     1              ${EMPTY}           OK: Interface 'lo' Status : up (admin: up)
            ...      3     [13]           --add-traffic      OK: All interfaces are ok
            ...      4     [13]           --add-traffic      OK: All interfaces are ok | 'traffic_in_lo'=0.00b/s;;;0;10000000 'traffic_out_lo'=0.00b/s;;;0;10000000 'traffic_in_eth1'=0.00b/s;;;0;1000000000 'traffic_out_eth1'=0.00b/s;;;0;1000000000
            ...      5     [234]          --add-traffic      OK: All interfaces are ok
            ...      6     [234]          --add-traffic      OK: All interfaces are ok | 'traffic_in_eth0'=0.00b/s;;;0;1000000000 'traffic_out_eth0'=0.00b/s;;;0;1000000000 'traffic_in_eth1'=0.00b/s;;;0;1000000000 'traffic_out_eth1'=0.00b/s;;;0;1000000000 'traffic_in_eth2'=0.00b/s;;;0;1000000000 'traffic_out_eth2'=0.00b/s;;;0;1000000000
