*** Settings ***
Documentation       network::huawei::standard::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::huawei::standard::snmp::plugin
...         --mode=gpon-ont-traffic
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=v2
...         --snmp-community=network/huawei/standard/snmp/huawei-gpon


*** Test Cases ***
Gpon-ont-traffic ${tc}
    [Tags]    network    huawei    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All ONT modules are ok
    ...    2
    ...    --include-serial=ANON00000001
    ...    OK: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) traffic in: 0.00 b/s, traffic in: 0.00 b/s, Up packets (per sec): 0, Down packets (per sec): 0, Up dropped packets (per sec): 0, Down drop packets (per sec): 0 | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    3
    ...    --exclude-serial=ANON00000001
    ...    OK: All ONT modules are ok
    ...    4
    ...    --warning-traffic-in=1:
    ...    WARNING: ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) traffic in: 0.00 b/s - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) traffic in: 0.00 b/s | 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;1:;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;1:;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    5
    ...    --critical-traffic-in=1:
    ...    CRITICAL: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) traffic in: 0.00 b/s - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) traffic in: 0.00 b/s - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) traffic in: 0.00 b/s | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;1:;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;1:;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;1:;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    6
    ...    --warning-traffic-out=1:
    ...    WARNING: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) traffic in: 0.00 b/s - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) traffic in: 0.00 b/s - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) traffic in: 0.00 b/s | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;1:;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;1:;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;1:;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    7
    ...    --critical-traffic-out=1:
    ...    CRITICAL: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) traffic in: 0.00 b/s - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) traffic in: 0.00 b/s - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) traffic in: 0.00 b/s | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;1:;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;1:;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;1:;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    8
    ...    --warning-down-packets=1:
    ...    WARNING: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) Down packets (per sec): 0 - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) Down packets (per sec): 0 - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) Down packets (per sec): 0 | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;1:;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;1:;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;1:;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    9
    ...    --critical-down-packets=1:
    ...    CRITICAL: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) Down packets (per sec): 0 - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) Down packets (per sec): 0 - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) Down packets (per sec): 0 | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;1:;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;1:;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;1:;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    10
    ...    --warning-up-packets=1:
    ...    WARNING: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) Up packets (per sec): 0 - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) Up packets (per sec): 0 - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) Up packets (per sec): 0 | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;1:;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;1:;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;1:;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    11
    ...    --critical-up-packets=1:
    ...    CRITICAL: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) Up packets (per sec): 0 - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) Up packets (per sec): 0 - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) Up packets (per sec): 0 | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;1:;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;1:;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;1:;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    12
    ...    --warning-up-drop-packets=1:
    ...    WARNING: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) Up dropped packets (per sec): 0 - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) Up dropped packets (per sec): 0 - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) Up dropped packets (per sec): 0 | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;1:;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;1:;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;1:;;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    13
    ...    --critical-up-drop-packets=1:
    ...    CRITICAL: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) Up dropped packets (per sec): 0 - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) Up dropped packets (per sec): 0 - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) Up dropped packets (per sec): 0 | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;1:;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;1:;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;1:;0; 'ont.packets.down.drop.persecond'=0packets/s;;;0;
    ...    14
    ...    --warning-down-drop-packets=1:
    ...    WARNING: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) Down drop packets (per sec): 0 - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) Down drop packets (per sec): 0 - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) Down drop packets (per sec): 0 | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;1:;;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;1:;;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;1:;;0;
    ...    15
    ...    --critical-down-drop-packets=1:
    ...    CRITICAL: ONT xDSL ANO 1 ANON00000001(414E4F4E00000001) Down drop packets (per sec): 0 - ONT xDSL ANO 2 ANON00000002(414E4F4E00000002) Down drop packets (per sec): 0 - ONT DSLAM ANO 3 ANON00000003(414E4F4E00000003) Down drop packets (per sec): 0 | 'xDSL ANO 1#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 1#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;1:;0; 'xDSL ANO 2#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'xDSL ANO 2#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;1:;0; 'DSLAM ANO 3#ont.traffic.in.bitspersecond'=0.00b/s;;;0; 'DSLAM ANO 3#ont.traffic.out.bitspersecond'=0.00b/s;;;0; 'ont.packets.up.persecond'=0packets/s;;;0; 'ont.packets.down.persecond'=0packets/s;;;0; 'ont.packets.up.drop.persecond'=0packets/s;;;0; 'ont.packets.down.drop.persecond'=0packets/s;;1:;0;
