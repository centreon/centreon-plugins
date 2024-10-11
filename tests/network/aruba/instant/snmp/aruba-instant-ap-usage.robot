*** Settings ***
Documentation       Network Aruba Instant SNMP plugin - AP Usage

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS} --plugin=network::aruba::instant::snmp::plugin --mode=ap-usage --hostname=${HOSTNAME} --snmp-version=${SNMPVERSION} --snmp-port=${SNMPPORT}

*** Test Cases ***
Test AP usage ${documentation} ${tc}
    [Tags]    network    aruba    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --filter-counters='${filtercounters}'
    ...    --filter-name='${filtername}'
    ...    --warning-clients='${warningclients}'
    ...    --snmp-community=${snmpcommunity}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  documentation                                                            snmpcommunity                          filtercounters      filtername     warningclients    expected_result    --
            ...       1   without filters                                            network/aruba/instant/snmp/ap-usage    ${EMPTY}            ${EMPTY}       ${EMPTY}          OK: total access points: 5 - All access points are ok | 'accesspoints.total.count'=5;;;0; 'AP Piso 1#clients.current.count'=4;;;0; 'AP Piso 1#cpu.utilization.percentage'=3.00%;;;0;100 'AP Piso 1#memory.usage.bytes'=215711744B;;;0;527028224 'AP Piso 1#memory.free.bytes'=311316480B;;;0;527028224 'AP Piso 1#memory.usage.percentage'=40.93%;;;0;100 'AP Piso 2#clients.current.count'=17;;;0; 'AP Piso 2#cpu.utilization.percentage'=18.00%;;;0;100 'AP Piso 2#memory.usage.bytes'=219455488B;;;0;527028224 'AP Piso 2#memory.free.bytes'=307572736B;;;0;527028224 'AP Piso 2#memory.usage.percentage'=41.64%;;;0;100 'AP Piso 3#clients.current.count'=14;;;0; 'AP Piso 3#cpu.utilization.percentage'=18.00%;;;0;100 'AP Piso 3#memory.usage.bytes'=219185152B;;;0;527028224 'AP Piso 3#memory.free.bytes'=307843072B;;;0;527028224 'AP Piso 3#memory.usage.percentage'=41.59%;;;0;100 'AP Piso 4#clients.current.count'=11;;;0; 'AP Piso 4#cpu.utilization.percentage'=11.00%;;;0;100 'AP Piso 4#memory.usage.bytes'=221700096B;;;0;527028224 'AP Piso 4#memory.free.bytes'=305328128B;;;0;527028224 'AP Piso 4#memory.usage.percentage'=42.07%;;;0;100 'AP Sotano#clients.current.count'=4;;;0; 'AP Sotano#cpu.utilization.percentage'=4.00%;;;0;100 'AP Sotano#memory.usage.bytes'=217473024B;;;0;527028224 'AP Sotano#memory.free.bytes'=309555200B;;;0;527028224 'AP Sotano#memory.usage.percentage'=41.26%;;;0;100
            ...       2   with filter on clients                                     network/aruba/instant/snmp/ap-usage    clients             ${EMPTY}       ${EMPTY}          OK: All access points are ok | 'AP Piso 1#clients.current.count'=4;;;0; 'AP Piso 2#clients.current.count'=17;;;0; 'AP Piso 3#clients.current.count'=14;;;0; 'AP Piso 4#clients.current.count'=11;;;0; 'AP Sotano#clients.current.count'=4;;;0;
            ...       4   with filter on clients and filter on name                  network/aruba/instant/snmp/ap-usage    clients             Piso 4         ${EMPTY}          OK: Access Point 'AP Piso 4' Current Clients: 11 | 'AP Piso 4#clients.current.count'=11;;;0;
            ...       5   without filters with warning when less than 20 clients     network/aruba/instant/snmp/ap-usage    ${EMPTY}            ${EMPTY}       20:               WARNING: Access Point 'AP Piso 1' Current Clients: 4 - Access Point 'AP Piso 2' Current Clients: 17 - Access Point 'AP Piso 3' Current Clients: 14 - Access Point 'AP Piso 4' Current Clients: 11 - Access Point 'AP Sotano' Current Clients: 4 | 'accesspoints.total.count'=5;;;0; 'AP Piso 1#clients.current.count'=4;20:;;0; 'AP Piso 1#cpu.utilization.percentage'=3.00%;;;0;100 'AP Piso 1#memory.usage.bytes'=215711744B;;;0;527028224 'AP Piso 1#memory.free.bytes'=311316480B;;;0;527028224 'AP Piso 1#memory.usage.percentage'=40.93%;;;0;100 'AP Piso 2#clients.current.count'=17;20:;;0; 'AP Piso 2#cpu.utilization.percentage'=18.00%;;;0;100 'AP Piso 2#memory.usage.bytes'=219455488B;;;0;527028224 'AP Piso 2#memory.free.bytes'=307572736B;;;0;527028224 'AP Piso 2#memory.usage.percentage'=41.64%;;;0;100 'AP Piso 3#clients.current.count'=14;20:;;0; 'AP Piso 3#cpu.utilization.percentage'=18.00%;;;0;100 'AP Piso 3#memory.usage.bytes'=219185152B;;;0;527028224 'AP Piso 3#memory.free.bytes'=307843072B;;;0;527028224 'AP Piso 3#memory.usage.percentage'=41.59%;;;0;100 'AP Piso 4#clients.current.count'=11;20:;;0; 'AP Piso 4#cpu.utilization.percentage'=11.00%;;;0;100 'AP Piso 4#memory.usage.bytes'=221700096B;;;0;527028224 'AP Piso 4#memory.free.bytes'=305328128B;;;0;527028224 'AP Piso 4#memory.usage.percentage'=42.07%;;;0;100 'AP Sotano#clients.current.count'=4;20:;;0; 'AP Sotano#cpu.utilization.percentage'=4.00%;;;0;100 'AP Sotano#memory.usage.bytes'=217473024B;;;0;527028224 'AP Sotano#memory.free.bytes'=309555200B;;;0;527028224 'AP Sotano#memory.usage.percentage'=41.26%;;;0;100