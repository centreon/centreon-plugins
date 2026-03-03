*** Settings ***
Documentation       Check sd-wan links.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::fortinet::fortigate::snmp::plugin


*** Test Cases ***
sdwan ${tc}
    [Tags]    network    sdwan
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=sdwan
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/fortinet/fortigate/snmp/fortinet-fortigate
    ...    --snmp-timeout=10
    ...    --snmp-retries=3
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                                expected_result    --
            ...      1     --filter-vdom='root'                                                                                         OK: sd-wan 'fgVWLHealthCheckLinkName' [vdom: root] [interface: wan1] state: up - traffic in: 27.45 Mb/s, out: 29.55 Mb/s, bi: 57.01 Mb/s - latency: 8.617ms - jitter: 0.065ms - packet loss: 0.000% | 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.in.bitspersecond'=27453000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.out.bitspersecond'=29552000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.bi.bitspersecond'=57005000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.latency.milliseconds'=8.62ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.jitter.milliseconds'=0.07ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.packetloss.percentage'=0.000%;;;0;100
            ...      2     --unknown-status='\\\%{vdom} eq "root"'                                                                      UNKNOWN: sd-wan 'fgVWLHealthCheckLinkName' [vdom: root] [interface: wan1] state: up | 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.in.bitspersecond'=27453000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.out.bitspersecond'=29552000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.bi.bitspersecond'=57005000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.latency.milliseconds'=8.62ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.jitter.milliseconds'=0.07ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.packetloss.percentage'=0.000%;;;0;100
            ...      3     --warning-status='\\\%{state} eq "up"'                                                                       WARNING: sd-wan 'fgVWLHealthCheckLinkName' [vdom: root] [interface: wan1] state: up | 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.in.bitspersecond'=27453000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.out.bitspersecond'=29552000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.bi.bitspersecond'=57005000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.latency.milliseconds'=8.62ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.jitter.milliseconds'=0.07ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.packetloss.percentage'=0.000%;;;0;100
            ...      4     --critical-status='\\\%{state} eq "up"'                                                                      CRITICAL: sd-wan 'fgVWLHealthCheckLinkName' [vdom: root] [interface: wan1] state: up | 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.in.bitspersecond'=27453000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.out.bitspersecond'=29552000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.bi.bitspersecond'=57005000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.latency.milliseconds'=8.62ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.jitter.milliseconds'=0.07ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.packetloss.percentage'=0.000%;;;0;100
            ...      5     --critical-status='\\\%{vdom} eq "root"' --warning-traffic-in=0 --critical-traffic-in=8                      CRITICAL: sd-wan 'fgVWLHealthCheckLinkName' [vdom: root] [interface: wan1] state: up - traffic in: 27.45 Mb/s | 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.in.bitspersecond'=27453000b/s;0:0;0:8;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.out.bitspersecond'=29552000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.bi.bitspersecond'=57005000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.latency.milliseconds'=8.62ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.jitter.milliseconds'=0.07ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.packetloss.percentage'=0.000%;;;0;100
            ...      6     ${EMPTY}                                                                                                     OK: sd-wan 'fgVWLHealthCheckLinkName' [vdom: root] [interface: wan1] state: up - traffic in: 27.45 Mb/s, out: 29.55 Mb/s, bi: 57.01 Mb/s - latency: 8.617ms - jitter: 0.065ms - packet loss: 0.000% | 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.in.bitspersecond'=27453000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.out.bitspersecond'=29552000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.bi.bitspersecond'=57005000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.latency.milliseconds'=8.62ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.jitter.milliseconds'=0.07ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.packetloss.percentage'=0.000%;;;0;100
            ...      7     --warning-status='\\\%{vdom} eq "root"' --warning-latency=8 --critical-latency=16                            WARNING: sd-wan 'fgVWLHealthCheckLinkName' [vdom: root] [interface: wan1] state: up - latency: 8.617ms | 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.in.bitspersecond'=27453000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.out.bitspersecond'=29552000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.traffic.bi.bitspersecond'=57005000b/s;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.latency.milliseconds'=8.62ms;0:8;0:16;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.jitter.milliseconds'=0.07ms;;;0; 'root~fgVWLHealthCheckLinkName~wan1#sdwan.packetloss.percentage'=0.000%;;;0;100
