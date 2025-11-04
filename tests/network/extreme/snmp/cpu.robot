*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::extreme::snmp::plugin


*** Test Cases ***
cpu-x435-8p-4s ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/extreme/snmp/x435-8p-4s
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      extra_options                                          expected_result    --
            ...      1.0     --filter-counters='.*'                                 OK: CPU '1' 5 seconds : 6.30 %, 10 seconds : 5.60 %, 30 seconds : 5.70 %, 1 minute : 6.70 %, 5 minutes : 2.10 % | 'cpu_5secs'=6.30%;;;0;100 'cpu_10secs'=5.60%;;;0;100 'cpu_30secs'=5.70%;;;0;100 'cpu_1min'=6.70%;;;0;100 'cpu_5min'=2.10%;;;0;100
            ...      2.0     --filter-counters='^5secs$'                            OK: CPU '1' 5 seconds : 6.30 % | 'cpu_5secs'=6.30%;;;0;100
            ...      2.1     --filter-counters='^5secs$' --warning-5secs=0:0        WARNING: CPU '1' 5 seconds : 6.30 % | 'cpu_5secs'=6.30%;0:0;;0;100
            ...      2.2     --filter-counters='^5secs$' --critical-5secs=0:0       CRITICAL: CPU '1' 5 seconds : 6.30 % | 'cpu_5secs'=6.30%;;0:0;0;100
            ...      3.0     --filter-counters='^10secs$'                           OK: CPU '1' 10 seconds : 5.60 % | 'cpu_10secs'=5.60%;;;0;100
            ...      3.1     --filter-counters='^10secs$' --warning-10secs=0:0      WARNING: CPU '1' 10 seconds : 5.60 % | 'cpu_10secs'=5.60%;0:0;;0;100
            ...      3.2     --filter-counters='^10secs$' --critical-10secs=0:0     CRITICAL: CPU '1' 10 seconds : 5.60 % | 'cpu_10secs'=5.60%;;0:0;0;100
            ...      4.0     --filter-counters='^30secs$'                           OK: CPU '1' 30 seconds : 5.70 % | 'cpu_30secs'=5.70%;;;0;100
            ...      4.1     --filter-counters='^30secs$' --warning-30secs=0:0      WARNING: CPU '1' 30 seconds : 5.70 % | 'cpu_30secs'=5.70%;0:0;;0;100
            ...      4.2     --filter-counters='^30secs$' --critical-30secs=0:0     CRITICAL: CPU '1' 30 seconds : 5.70 % | 'cpu_30secs'=5.70%;;0:0;0;100
            ...      5.0     --filter-counters='^1min$'                             OK: CPU '1' 1 minute : 6.70 % | 'cpu_1min'=6.70%;;;0;100
            ...      5.1     --filter-counters='^1min$' --warning-1min=0:0          WARNING: CPU '1' 1 minute : 6.70 % | 'cpu_1min'=6.70%;0:0;;0;100
            ...      5.2     --filter-counters='^1min$' --critical-1min=0:0         CRITICAL: CPU '1' 1 minute : 6.70 % | 'cpu_1min'=6.70%;;0:0;0;100
            ...      6.0     --filter-counters='^5min$'                             OK: CPU '1' 5 minutes : 2.10 % | 'cpu_5min'=2.10%;;;0;100
            ...      6.1     --filter-counters='^5min$' --warning-5min=0:0          WARNING: CPU '1' 5 minutes : 2.10 % | 'cpu_5min'=2.10%;0:0;;0;100
            ...      6.2     --filter-counters='^5min$' --critical-5min=0:0         CRITICAL: CPU '1' 5 minutes : 2.10 % | 'cpu_5min'=2.10%;;0:0;0;100
