*** Settings ***
Documentation       network::stormshield::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::stormshield::snmp::plugin
...         --mode=router-objects
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}
...         --snmp-community=network/stormshield/snmp/sn910


*** Test Cases ***
Router-objects ${tc}
    [Tags]    network    stormshield    snmp
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
    ...    OK: All gateways are working (1/1 principal, 0/0 backup). | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    2
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>display</element> <element>gateway_count</element> <element>principal_count</element> <element>backup_count</element> <element>gateways_summary</element> </data>
    ...    3
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label backup_count="0" display="dr4_router" gateway_count="1" gateways_summary="fw_gateway(Principal)" principal_count="1"/> </data>
    ...    4
    ...    --disco-show --include-name=unknown
    ...    <?xml version="1.0" encoding="utf-8"?> <data/>
    ...    5
    ...    --include-name=^dr4
    ...    OK: All gateways are working (1/1 principal, 0/0 backup). | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    6
    ...    --exclude-name=dr4
    ...    UNKNOWN: No router object found.
    ...    7
    ...    --warning-router-status='\\\%{principal_total} == 1'
    ...    WARNING: All gateways are working (1/1 principal, 0/0 backup). | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    8
    ...    --critical-router-status='\\\%{principal_total} == 1'
    ...    CRITICAL: All gateways are working (1/1 principal, 0/0 backup). | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    9
    ...    --warning-principal-count=@0:0
    ...    WARNING: principal gateways down: 0/1. | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;@0:0;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    10
    ...    --critical-principal-count=@0:0
    ...    CRITICAL: principal gateways down: 0/1. | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;@0:0;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    11
    ...    --warning-backup-count=@0:0
    ...    WARNING: backup gateways down: 0/0. | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;@0:0;;0;0
    ...    12
    ...    --critical-backup-count=@0:0
    ...    CRITICAL: backup gateways down: 0/0. | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;@0:0;0;0
    ...    13
    ...    --warning-packet-loss=@0:0
    ...    WARNING: packet loss: gateway 'fw_gateway' 0% (warning). | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;@0:0;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    14
    ...    --critical-packet-loss=@0:0
    ...    CRITICAL: packet loss: gateway 'fw_gateway' 0% (critical). | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;@0:0;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    15
    ...    --warning-latency=0
    ...    WARNING: latency: gateway 'fw_gateway' 1 ms (warning). | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;0:0;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    16
    ...    --critical-latency=0
    ...    CRITICAL: latency: gateway 'fw_gateway' 1 ms (critical). | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;0:0;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    17
    ...    --warning-jitter=@0:0
    ...    WARNING: jitter: gateway 'fw_gateway' 0 ms (warning). | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;@0:0;;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
    ...    18
    ...    --critical-jitter=@0:0
    ...    CRITICAL: jitter: gateway 'fw_gateway' 0 ms (critical). | 'dr4_router~fw_gateway#router.gateway.packetloss.percentage'=0%;;;0;100 'dr4_router~fw_gateway#router.gateway.latency.milliseconds'=1ms;;;0; 'dr4_router~fw_gateway#router.gateway.jitter.milliseconds'=0ms;;@0:0;0; 'dr4_router#router.gateway.principal.down.count'=0;;;0;1 'dr4_router#router.gateway.backup.down.count'=0;;;0;0
