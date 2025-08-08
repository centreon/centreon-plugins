*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
tmm-usage ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=tmm-usage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                           expected_result    --
            ...      1     ${EMPTY}                                                                OK: All TMM are ok | '0.0#tmm.memory.usage.bytes'=2175382320B;;;0;22695378944 '0.0#tmm.cpu.utilization.1m.percentage'=15%;;;0;100 '0.0#tmm.cpu.utilization.5m.percentage'=15%;;;0;100 '0.0#tmm.connections.client.curent.count'=1324;;;0; '0.0#tmm.connections.server.current.count'=1303;;;0; '0.2#tmm.cpu.utilization.1m.percentage'=12%;;;0;100 '0.2#tmm.cpu.utilization.5m.percentage'=11%;;;0;100 '0.2#tmm.connections.client.curent.count'=1368;;;0; '0.2#tmm.connections.server.current.count'=1291;;;0; '0.4#tmm.cpu.utilization.1m.percentage'=11%;;;0;100 '0.4#tmm.cpu.utilization.5m.percentage'=10%;;;0;100 '0.4#tmm.connections.client.curent.count'=1369;;;0; '0.4#tmm.connections.server.current.count'=1331;;;0; '0.6#tmm.cpu.utilization.1m.percentage'=18%;;;0;100 '0.6#tmm.cpu.utilization.5m.percentage'=12%;;;0;100 '0.6#tmm.connections.client.curent.count'=1331;;;0; '0.6#tmm.connections.server.current.count'=1324;;;0;
            ...      2     --filter-counters=''                                                    OK: All TMM are ok
            ...      3     --filter-name='TMM'                                                     UNKNOWN: No TMM found.
            ...      4     --critical-cpu-1m=12                                                    CRITICAL: TMM '0.0' CPU Usage 1min : 15 % - TMM '0.6' CPU Usage 1min : 18 % | '0.0#tmm.memory.usage.bytes'=2175382320B;;;0;22695378944
            ...      5     --warning-cpu-5m=10                                                     WARNING: TMM '0.0' CPU Usage 5min : 15 % - TMM '0.2' CPU Usage 5min : 11 % - TMM '0.6' CPU Usage 5min : 12 % | '0.0#tmm.memory.usage.bytes'=2175382320B;;;0;22695378944