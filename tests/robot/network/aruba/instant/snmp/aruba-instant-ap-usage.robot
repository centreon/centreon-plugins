*** Settings ***
Documentation       Network Aruba Instant SNMP plugin - AP Usage

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS} --plugin=network::aruba::instant::snmp::plugin --mode=ap-usage --hostname=127.0.0.1 --snmp-version=2c --snmp-port=2024

&{ap_usage_test_1}
...                     documentation=Test AP usage without filters
...                     snmpcommunity=network/aruba/instant/snmp/ap-usage
...                     filtercounters=
...                     filtername=
...                     warningclients=
...                     criticalclients=
...                     result=OK: total access points: 5 - All access points are ok | 'accesspoints.total.count'=5;;;0; 'AP Piso 1#clients.current.count'=4;;;0; 'AP Piso 1#cpu.utilization.percentage'=3.00%;;;0;100 'AP Piso 1#memory.usage.bytes'=215711744B;;;0;527028224 'AP Piso 1#memory.free.bytes'=311316480B;;;0;527028224 'AP Piso 1#memory.usage.percentage'=40.93%;;;0;100 'AP Piso 2#clients.current.count'=17;;;0; 'AP Piso 2#cpu.utilization.percentage'=18.00%;;;0;100 'AP Piso 2#memory.usage.bytes'=219455488B;;;0;527028224 'AP Piso 2#memory.free.bytes'=307572736B;;;0;527028224 'AP Piso 2#memory.usage.percentage'=41.64%;;;0;100 'AP Piso 3#clients.current.count'=14;;;0; 'AP Piso 3#cpu.utilization.percentage'=18.00%;;;0;100 'AP Piso 3#memory.usage.bytes'=219185152B;;;0;527028224 'AP Piso 3#memory.free.bytes'=307843072B;;;0;527028224 'AP Piso 3#memory.usage.percentage'=41.59%;;;0;100 'AP Piso 4#clients.current.count'=11;;;0; 'AP Piso 4#cpu.utilization.percentage'=11.00%;;;0;100 'AP Piso 4#memory.usage.bytes'=221700096B;;;0;527028224 'AP Piso 4#memory.free.bytes'=305328128B;;;0;527028224 'AP Piso 4#memory.usage.percentage'=42.07%;;;0;100 'AP Sotano#clients.current.count'=4;;;0; 'AP Sotano#cpu.utilization.percentage'=4.00%;;;0;100 'AP Sotano#memory.usage.bytes'=217473024B;;;0;527028224 'AP Sotano#memory.free.bytes'=309555200B;;;0;527028224 'AP Sotano#memory.usage.percentage'=41.26%;;;0;100

&{ap_usage_test_2}
...                     documentation=Test AP usage with filter on clients
...                     snmpcommunity=network/aruba/instant/snmp/ap-usage
...                     filtercounters=clients
...                     filtername=
...                     warningclients=
...                     criticalclients=
...                     result=OK: All access points are ok | 'AP Piso 1#clients.current.count'=4;;;0; 'AP Piso 2#clients.current.count'=17;;;0; 'AP Piso 3#clients.current.count'=14;;;0; 'AP Piso 4#clients.current.count'=11;;;0; 'AP Sotano#clients.current.count'=4;;;0;

&{ap_usage_test_3}
...                     documentation=Test AP usage with filter on clients and filter on name
...                     snmpcommunity=network/aruba/instant/snmp/ap-usage
...                     filtercounters=clients
...                     filtername=Piso 4
...                     warningclients=
...                     criticalclients=
...                     result=OK: Access Point 'AP Piso 4' Current Clients: 11 | 'AP Piso 4#clients.current.count'=11;;;0;

&{ap_usage_test_4}
...                     documentation=Test AP usage without filters with warning when less than 20 clients
...                     snmpcommunity=network/aruba/instant/snmp/ap-usage
...                     filtercounters=
...                     filtername=
...                     warningclients=20:
...                     criticalclients=
...                     result=WARNING: Access Point 'AP Piso 1' Current Clients: 4 - Access Point 'AP Piso 2' Current Clients: 17 - Access Point 'AP Piso 3' Current Clients: 14 - Access Point 'AP Piso 4' Current Clients: 11 - Access Point 'AP Sotano' Current Clients: 4 | 'accesspoints.total.count'=5;;;0; 'AP Piso 1#clients.current.count'=4;20:;;0; 'AP Piso 1#cpu.utilization.percentage'=3.00%;;;0;100 'AP Piso 1#memory.usage.bytes'=215711744B;;;0;527028224 'AP Piso 1#memory.free.bytes'=311316480B;;;0;527028224 'AP Piso 1#memory.usage.percentage'=40.93%;;;0;100 'AP Piso 2#clients.current.count'=17;20:;;0; 'AP Piso 2#cpu.utilization.percentage'=18.00%;;;0;100 'AP Piso 2#memory.usage.bytes'=219455488B;;;0;527028224 'AP Piso 2#memory.free.bytes'=307572736B;;;0;527028224 'AP Piso 2#memory.usage.percentage'=41.64%;;;0;100 'AP Piso 3#clients.current.count'=14;20:;;0; 'AP Piso 3#cpu.utilization.percentage'=18.00%;;;0;100 'AP Piso 3#memory.usage.bytes'=219185152B;;;0;527028224 'AP Piso 3#memory.free.bytes'=307843072B;;;0;527028224 'AP Piso 3#memory.usage.percentage'=41.59%;;;0;100 'AP Piso 4#clients.current.count'=11;20:;;0; 'AP Piso 4#cpu.utilization.percentage'=11.00%;;;0;100 'AP Piso 4#memory.usage.bytes'=221700096B;;;0;527028224 'AP Piso 4#memory.free.bytes'=305328128B;;;0;527028224 'AP Piso 4#memory.usage.percentage'=42.07%;;;0;100 'AP Sotano#clients.current.count'=4;20:;;0; 'AP Sotano#cpu.utilization.percentage'=4.00%;;;0;100 'AP Sotano#memory.usage.bytes'=217473024B;;;0;527028224 'AP Sotano#memory.free.bytes'=309555200B;;;0;527028224 'AP Sotano#memory.usage.percentage'=41.26%;;;0;100

@{ap_usage_tests}
...                     &{ap_usage_test_1}
...                     &{ap_usage_test_2}
...                     &{ap_usage_test_3}
...                     &{ap_usage_test_4}


*** Test Cases ***
Network Aruba Instant SNMP plugin
    [Documentation]    AP Usage
    [Tags]    network    aruba    snmp
    FOR    ${ap_usage_tc}    IN    @{ap_usage_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --filter-counters='${ap_usage_tc.filtercounters}'
        ...    --filter-name='${ap_usage_tc.filtername}'
        ...    --warning-clients='${ap_usage_tc.warningclients}'
        ...    --critical-clients='${ap_usage_tc.criticalclients}'
        ...    --snmp-community=${ap_usage_tc.snmpcommunity}

        Log To Console    ${command}
        ${output}    Run    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${ap_usage_tc.result}
        ...    Wrong output result for compliance of ${ap_usage_tc.result}{\n}Command output:{\n}${output}{\n}{\n}{\n}
    END
