*** Settings ***
Documentation       Forcepoint SD-WAN Mode Network Interfaces

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::forcepoint::sdwan::snmp::plugin
...         --mode=interfaces
...         --hostname=${HOSTNAME}
...         --snmp-port=40000
...         --snmp-community=network/forcepoint/sdwan/snmp/forcepoint-interfaces

${COND}     ${PERCENT}\{sub\} =~ /exited/ && ${PERCENT}{display} =~ /network/'


*** Test Cases ***
Interfaces by id ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --interface='${filter}'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    filter                    extra_options                 expected_result    --
            ...      1     1                         ${EMPTY}                      OK: Interface 'lo' Status : up (admin: up)
            ...      2     1,3                       ${EMPTY}                      OK: All interfaces are ok
            ...      3     1,3                       --add-traffic                 OK: All interfaces are ok
            ...      4     1,3                       --add-traffic                 OK: All interfaces are ok | 'traffic_in_lo'=0.00b/s;;;0;10000000 'traffic_out_lo'=0.00b/s;;;0;10000000 'traffic_in_Anonymized 184'=0.00b/s;;;0; 'traffic_out_Anonymized 184'=0.00b/s;;;0;
            ...      5     2,3,4                     ${EMPTY}                      OK: All interfaces are ok
            ...      6     2,3,4                     --add-traffic                 OK: All interfaces are ok
            ...      7     2,3,4                     --add-traffic                 OK: All interfaces are ok | 'traffic_in_Anonymized 184'=0.00b/s;;;0; 'traffic_out_Anonymized 184'=0.00b/s;;;0; 'traffic_in_abc0'=0.00b/s;;;0;1000000000 'traffic_out_abc0'=0.00b/s;;;0;1000000000
# theese test are linked together. The test 3 create the cache file in /dev/shm/, and the test 4 use this cache file
# to calculate traffic throughput by second.

Interfaces by id regexp ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --interface='${filter}'
    ...    --regex-id
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    filter         extra_options      expected_result    --
            ...      1     ^1$            ${EMPTY}           OK: Interface 'lo' Status : up (admin: up)
            ...      2     9              ${EMPTY}           OK: Interface 'prq5' Status : up (admin: up)
            ...      3     10|13          ${EMPTY}           OK: All interfaces are ok
            ...      4     10|13          --add-traffic      OK: All interfaces are ok
            ...      5     10|13          --add-traffic      OK: All interfaces are ok | 'traffic_in_stu6'=0.00b/s;;;0;1000000000 'traffic_out_stu6'=0.00b/s;;;0;1000000000 'traffic_in_Anonymized 071'=0.00b/s;;;0;1000000000 'traffic_out_Anonymized 071'=0.00b/s;;;0;1000000000
            ...      6     [234]          ${EMPTY}           OK: All interfaces are ok
            ...      7     [234]          --add-traffic      OK: All interfaces are ok
            ...      8     [234]          --add-traffic      OK: All interfaces are ok | 'traffic_in_Anonymized 073'=0.00b/s;;;0; 'traffic_out_Anonymized 073'=0.00b/s;;;0; 'traffic_in_Anonymized 071'=0.00b/s;;;0;1000000000 'traffic_out_Anonymized 071'=0.00b/s;;;0;1000000000 'traffic_in_Anonymized 073'=0.00b/s;;;0;1000000000 'traffic_out_Anonymized 073'=0.00b/s;;;0;1000000000 'traffic_in_Anonymized 184'=0.00b/s;;;0; 'traffic_out_Anonymized 184'=0.00b/s;;;0; 'traffic_in_abc0'=0.00b/s;;;0;1000000000 'traffic_out_abc0'=0.00b/s;;;0;1000000000
