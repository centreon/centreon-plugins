*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
cpu-usage ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu-usage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/cpu
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                    expected_result    --
            ...      1     ${EMPTY} --filter-counters='^usage-5s' --filter-name='10'                        OK: CPU '10' CPU Usage 5sec : 35 % | 'usage_5s'=35%;;;0;100
            ...      2     --filter-name='12'                                                               OK: CPU '12' CPU Usage 5sec : 36 %, CPU Usage 1min : 36 %, CPU Usage 5min : 36 %, CPU User 5sec : 31 %, CPU User 1min : 31 %, CPU User 5min : 32 %, CPU IO Wait 5sec : 0 %, CPU IO Wait 1min : 0 %, CPU IO Wait 5min : 0 %, CPU System 5sec : 3 %, CPU System 1min : 4 %, CPU System 5min : 3 %, CPU Idle 5sec : 62 %, CPU Idle 1min : 62 %, CPU Idle 5min : 62 % | 'usage_5s'=36%;;;0;100 'usage_1m'=36%;;;0;100 'usage_5m'=36%;;;0;100 'user_5s'=31%;;;0;100 'user_1m'=31%;;;0;100 'user_5m'=32%;;;0;100 'iowait_5s'=0%;;;0;100 'iowait_1m'=0%;;;0;100 'iowait_5m'=0%;;;0;100 'system_5s'=3%;;;0;100 'system_1m'=4%;;;0;100 'system_5m'=3%;;;0;100 'idle_5s'=62%;;;0;100 'idle_1m'=62%;;;0;100 'idle_5m'=62%;;;0;100
            ...      3     --warning-usage-1m='30' --filter-counters='^usage-1m' --filter-name='0'          WARNING: CPU '0' CPU Usage 1min : 39 % - CPU '10' CPU Usage 1min : 35 % - CPU '20' CPU Usage 1min : 38 % - CPU '30' CPU Usage 1min : 31 % | 'usage_1m_0'=39%;0:30;;0;100 'usage_1m_10'=35%;0:30;;0;100 'usage_1m_20'=38%;0:30;;0;100 'usage_1m_30'=31%;0:30;;0;100 'usage_1m_40'=29%;0:30;;0;100 'usage_1m_50'=30%;0:30;;0;100
            ...      4     --critical-usage-5m='32' --filter-counters='^usage-5m' --filter-name='0'         CRITICAL: CPU '0' CPU Usage 5min : 39 % - CPU '10' CPU Usage 5min : 37 % - CPU '20' CPU Usage 5min : 38 % | 'usage_5m_0'=39%;;0:32;0;100 'usage_5m_10'=37%;;0:32;0;100 'usage_5m_20'=38%;;0:32;0;100 'usage_5m_30'=31%;;0:32;0;100 'usage_5m_40'=29%;;0:32;0;100 'usage_5m_50'=30%;;0:32;0;100