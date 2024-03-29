*** Settings ***
Documentation       Network Interfaces

Library             OperatingSystem
Library             String
Library             Examples

Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}     ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                  perl ${CENTREON_PLUGINS}
...                     --plugin=os::linux::snmp::plugin
...                     --mode=interfaces
...                     --hostname=127.0.0.1
...                     --snmp-port=2024
...                     --snmp-community=network-interfaces
...                     --statefile-dir=/tmp/

${PERCENT}              %

${COND}                 ${PERCENT}\{sub\} =~ /exited/ && ${PERCENT}{display} =~ /network/'


*** Test Cases ***
Interfaces by id ${tc}/5
    [Tags]    os    linux    network    interfaces
    ${command}    Catenate
    ...    ${CMD}
    ...    --interface='${filter}'
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:
    ...    tc
    ...    filter
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    1
    ...    ${EMPTY}
    ...    OK: Interface 'lo' Status : up (admin: up)
    ...    2
    ...    1,3
    ...    --add-traffic
    ...    OK: All interfaces are ok
    ...    3
    ...    1,3
    ...    --add-traffic
    ...    OK: All interfaces are ok | 'traffic_in_lo'=0.00b/s;;;0;10000000 'traffic_out_lo'=0.00b/s;;;0;10000000 'traffic_in_eth1'=0.00b/s;;;0;1000000000 'traffic_out_eth1'=0.00b/s;;;0;1000000000
    ...    4
    ...    2,3,4
    ...    --add-traffic
    ...    OK: All interfaces are ok
    ...    5
    ...    2,3,4
    ...    --add-traffic
    ...    OK: All interfaces are ok | 'traffic_in_eth0'=0.00b/s;;;0;1000000000 'traffic_out_eth0'=0.00b/s;;;0;1000000000 'traffic_in_eth1'=0.00b/s;;;0;1000000000 'traffic_out_eth1'=0.00b/s;;;0;1000000000 'traffic_in_eth2'=0.00b/s;;;0;1000000000 'traffic_out_eth2'=0.00b/s;;;0;1000000000

Interfaces by id regexp ${tc}/6
    [Tags]    os    linux    network    interfaces
    ${command}    Catenate
    ...    ${CMD}
    ...    --interface='${filter}'
    ...    --regex-id
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:
    ...    tc
    ...    filter
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ^1$
    ...    ${EMPTY}
    ...    OK: Interface 'lo' Status : up (admin: up)
    ...    2
    ...    1
    ...    ${EMPTY}
    ...    OK: Interface 'lo' Status : up (admin: up)
    ...    3
    ...    [13]
    ...    --add-traffic
    ...    OK: All interfaces are ok
    ...    4
    ...    [13]
    ...    --add-traffic
    ...    OK: All interfaces are ok | 'traffic_in_lo'=0.00b/s;;;0;10000000 'traffic_out_lo'=0.00b/s;;;0;10000000 'traffic_in_eth1'=0.00b/s;;;0;1000000000 'traffic_out_eth1'=0.00b/s;;;0;1000000000
    ...    5
    ...    [234]
    ...    --add-traffic
    ...    OK: All interfaces are ok
    ...    6
    ...    [234]
    ...    --add-traffic
    ...    OK: All interfaces are ok | 'traffic_in_eth0'=0.00b/s;;;0;1000000000 'traffic_out_eth0'=0.00b/s;;;0;1000000000 'traffic_in_eth1'=0.00b/s;;;0;1000000000 'traffic_out_eth1'=0.00b/s;;;0;1000000000 'traffic_in_eth2'=0.00b/s;;;0;1000000000 'traffic_out_eth2'=0.00b/s;;;0;1000000000
