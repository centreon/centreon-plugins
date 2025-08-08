*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=os::f5os::snmp::plugin

*** Test Cases ***
cpu-usage ${tc}
    [Tags]    os    f5os    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu-usage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/f5os/snmp/f5os
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                    expected_result    --
            ...      1     ${EMPTY}                                                                         OK: CPU(s) average usage is: 8.00 % | 'cpu.usage.percent'=8.00%;;;0;100 '0#cpu.core.current.usage.percent'=0%;;;0;100 '0#cpu.core.usage.avg.5s.percent'=0%;;;0;100 '0#cpu.core.usage.avg.1m.percent'=1%;;;0;100 '0#cpu.core.usage.avg.5m.percent'=1%;;;0;100 '1#cpu.core.current.usage.percent'=16%;;;0;100 '1#cpu.core.usage.avg.5s.percent'=10%;;;0;100 '1#cpu.core.usage.avg.1m.percent'=15%;;;0;100 '1#cpu.core.usage.avg.5m.percent'=50%;;;0;100
            ...      2     --include-id='1'                                                                 OK: CPU(s) average usage is: 16.00 % - CPU '1' CPU Usage Current : 16 %, CPU Usage 5sec : 10 %, CPU Usage 1min : 15 %, CPU Usage 5min : 50 % | 'cpu.usage.percent'=16.00%;;;0;100 '1#cpu.core.current.usage.percent'=16%;;;0;100 '1#cpu.core.usage.avg.5s.percent'=10%;;;0;100 '1#cpu.core.usage.avg.1m.percent'=15%;;;0;100 '1#cpu.core.usage.avg.5m.percent'=50%;;;0;100
            ...      3     --include-name='Anonymized 118'                                                  OK: CPU(s) average usage is: 0.00 % - CPU '0' CPU Usage Current : 0 %, CPU Usage 5sec : 0 %, CPU Usage 1min : 1 %, CPU Usage 5min : 1 % | 'cpu.usage.percent'=0.00%;;;0;100 '0#cpu.core.current.usage.percent'=0%;;;0;100 '0#cpu.core.usage.avg.5s.percent'=0%;;;0;100 '0#cpu.core.usage.avg.1m.percent'=1%;;;0;100 '0#cpu.core.usage.avg.5m.percent'=1%;;;0;100
            ...      4     --critical-core-avg-1m=10                                                        CRITICAL: CPU '1' CPU Usage 1min : 15 % | 'cpu.usage.percent'=8.00%;;;0;100 '0#cpu.core.current.usage.percent'=0%;;;0;100 '0#cpu.core.usage.avg.5s.percent'=0%;;;0;100 '0#cpu.core.usage.avg.1m.percent'=1%;;0:10;0;100 '0#cpu.core.usage.avg.5m.percent'=1%;;;0;100 '1#cpu.core.current.usage.percent'=16%;;;0;100 '1#cpu.core.usage.avg.5s.percent'=10%;;;0;100 '1#cpu.core.usage.avg.1m.percent'=15%;;0:10;0;100 '1#cpu.core.usage.avg.5m.percent'=50%;;;0;100
            ...      5     --warning-core-avg-5m=20                                                         WARNING: CPU '1' CPU Usage 5min : 50 % | 'cpu.usage.percent'=8.00%;;;0;100 '0#cpu.core.current.usage.percent'=0%;;;0;100 '0#cpu.core.usage.avg.5s.percent'=0%;;;0;100 '0#cpu.core.usage.avg.1m.percent'=1%;;;0;100 '0#cpu.core.usage.avg.5m.percent'=1%;0:20;;0;100 '1#cpu.core.current.usage.percent'=16%;;;0;100 '1#cpu.core.usage.avg.5s.percent'=10%;;;0;100 '1#cpu.core.usage.avg.1m.percent'=15%;;;0;100 '1#cpu.core.usage.avg.5m.percent'=50%;0:20;;0;100
            ...      6     --include-id=1 --include-name='Anonymized 118'                                   OK: CPU(s) average usage is: 8.00 % | 'cpu.usage.percent'=8.00%;;;0;100 '0#cpu.core.current.usage.percent'=0%;;;0;100 '0#cpu.core.usage.avg.5s.percent'=0%;;;0;100 '0#cpu.core.usage.avg.1m.percent'=1%;;;0;100 '0#cpu.core.usage.avg.5m.percent'=1%;;;0;100 '1#cpu.core.current.usage.percent'=16%;;;0;100 '1#cpu.core.usage.avg.5s.percent'=10%;;;0;100 '1#cpu.core.usage.avg.1m.percent'=15%;;;0;100 '1#cpu.core.usage.avg.5m.percent'=50%;;;0;100
