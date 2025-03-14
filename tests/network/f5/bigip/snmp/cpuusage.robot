*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
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
 
    Ctn Verify Command Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                        expected_result    --
            ...      1     ${EMPTY}                             OK: All CPU are ok | 'usage_5s_0'=40%;;;0;100 'usage_1m_0'=39%;;;0;100 'usage_5m_0'=39%;;;0;100 'user_5s_0'=35%;;;0;100 'user_1m_0'=34%;;;0;100 'user_5m_0'=34%;;;0;100 'iowait_5s_0'=0%;;;0;100 'iowait_1m_0'=0%;;;0;100 'iowait_5m_0'=0%;;;0;100 'system_5s_0'=4%;;;0;100 'system_1m_0'=4%;;;0;100 'system_5m_0'=4%;;;0;100 'idle_5s_0'=58%;;;0;100 'idle_1m_0'=59%;;;0;100 'idle_5m_0'=59%;;;0;100 'usage_5s_1'=13%;;;0;100 'usage_1m_1'=15%;;;0;100 'usage_5m_1'=16%;;;0;100 'user_5s_1'=11%;;;0;100 'user_1m_1'=12%;;;0;100 'user_5m_1'=14%;;;0;100 'iowait_5s_1'=0%;;;0;100 'iowait_1m_1'=0%;;;0;100 'iowait_5m_1'=0%;;;0;100 'system_5s_1'=1%;;;0;100 'system_1m_1'=2%;;;0;100 'system_5m_1'=2%;;;0;100 'idle_5s_1'=86%;;;0;100 'idle_1m_1'=84%;;;0;100 'idle_5m_1'=83%;;;0;100 'usage_5s_10'=35%;;;0;100 'usage_1m_10'=35%;;;0;100 'usage_5m_10'=37%;;;0;100 'user_5s_10'=31%;;;0;100 'user_1m_10'=31%;;;0;100 'user_5m_10'=32%;;;0;100 'iowait_5s_10'=0%;;;0;100 'iowait_1m_10'=0%;;;0;100 'iowait_5m_10'=0%;;;0;100 'system_5s_10'=3%;;;0;100 'system_1m_10'=3%;;;0;100 'system_5m_10'=4%;;;0;100 'idle_5s_10'=62%;;;0;
            ...      2     --filter-counters='^usage$'          OK:
            ...      3     --filter-name='12'                   OK: CPU '12' CPU Usage 5sec : 36 %, CPU Usage 1min : 36 %, CPU Usage 5min : 36 %, CPU User 5sec : 31 %, CPU User 1min : 31 %, CPU User 5min : 32 %, CPU IO Wait 5sec : 0 %, CPU IO Wait 1min : 0 %, CPU IO Wait 5min : 0 %, CPU System 5sec : 3 %, CPU System 1min : 4 %, CPU System 5min : 3 %, CPU Idle 5sec : 62 %, CPU Idle 1min : 62 %, CPU Idle 5min : 62 % | 'usage_5s'=36%;;;0;100 'usage_1m'=36%;;;0;100 'usage_5m'=36%;;;0;100 'user_5s'=31%;;;0;100 'user_1m'=31%;;;0;100 'user_5m'=32%;;;0;100 'iowait_5s'=0%;;;0;100 'iowait_1m'=0%;;;0;100 'iowait_5m'=0%;;;0;100 'system_5s'=3%;;;0;100 'system_1m'=4%;;;0;100 'system_5m'=3%;;;0;100 'idle_5s'=62%;;;0;100 'idle_1m'=62%;;;0;100 'idle_5m'=62%;;;0;100
            ...      4     --warning-usage-1m='30'              WARNING: CPU '0' CPU Usage 1min : 39 % - CPU '10' CPU Usage 1min : 35 % - CPU '12' CPU Usage 1min : 36 % - CPU '14' CPU Usage 1min : 38 % - CPU '16' CPU Usage 1min : 38 % - CPU '18' CPU Usage 1min : 38 % - CPU '2' CPU Usage 1min : 38 % - CPU '20' CPU Usage 1min : 38 % - CPU '22' CPU Usage 1min : 37 % - CPU '24' CPU Usage 1min : 37 % - CPU '26' CPU Usage 1min : 37 % - CPU '28' CPU Usage 1min : 32 % - CPU '30' CPU Usage 1min : 31 % - CPU '4' CPU Usage 1min : 37 % - CPU '42' CPU Usage 1min : 31 % - CPU '6' CPU Usage 1min : 37 % - CPU '8' CPU Usage 1min : 36 % | 'usage_5s_0'=40%;;;0;100 'usage_1m_0'=39%;0:30;;0;100 'usage_5m_0'=39%;;;0;100 'user_5s_0'=35%;;;0;100 'user_1m_0'=34%;;;0;100 'user_5m_0'=34%;;;0;100 'iowait_5s_0'=0%;;;0;100 'iowait_1m_0'=0%;;;0;100 'iowait_5m_0'=0%;;;0;100 'system_5s_0'=4%;;;0;100 'system_1m_0'=4%;;;0;100 'system_5m_0'=4%;;;0;100 'idle_5s_0'=58%;;;0;100 'idle_1m_0'=59%;;;0;100 'idle_5m_0'=59%;;;0;100 'usage_5s_1'=13%;;;0;100 'usage_1m_1'=15%;0:30;;0;100
            ...      5     --critical-usage-5m='32'             CRITICAL: CPU '0' CPU Usage 5min : 39 % - CPU '10' CPU Usage 5min : 37 % - CPU '12' CPU Usage 5min : 36 % - CPU '14' CPU Usage 5min : 38 % - CPU '16' CPU Usage 5min : 38 % - CPU '18' CPU Usage 5min : 38 % - CPU '2' CPU Usage 5min : 38 % - CPU '20' CPU Usage 5min : 38 % - CPU '22' CPU Usage 5min : 37 % - CPU '24' CPU Usage 5min : 37 % - CPU '26' CPU Usage 5min : 37 % - CPU '4' CPU Usage 5min : 37 % - CPU '6' CPU Usage 5min : 37 % - CPU '8' CPU Usage 5min : 37 % | 'usage_5s_0'=40%;;;0;100 'usage_1m_0'=39%;;;0;100 'usage_5m_0'=39%;;0:32;0;100 'user_5s_0'=35%;;;0;100 'user_1m_0'=34%;;;0;100 'user_5m_0'=34%;;;0;100 'iowait_5s_0'=0%;;;0;100 'iowait_1m_0'=0%;;;0;100 'iowait_5m_0'=0%;;;0;100 'system_5s_0'=4%;;;0;100 'system_1m_0'=4%;;;0;100 'system_5m_0'=4%;;;0;100 'idle_5s_0'=58%;;;0;100 'idle_1m_0'=59%;;;0;100 'idle_5m_0'=59%;;;0;100 'usage_5s_1'=13%;;;0;100 'usage_1m_1'=15%;;;0;100 'usage_5m_1'=16%;;0:32;0;100 'user_5s_1'=11%;;;0;100 'user_1m_1'=12%;;;0;100 'user_5m_1'=14%;;;0;100