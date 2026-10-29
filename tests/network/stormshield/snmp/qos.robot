*** Settings ***
Documentation       network::stormshield::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::stormshield::snmp::plugin
...         --mode=qos
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}


*** Test Cases ***
# test cases run in order: the first run of a given filter only creates the cache
# (traffic rates show 'Buffer creation'), next runs compute 0 b/s as the snmpwalk is static
Qos SN910 ${tc}
    [Tags]    network    stormshield    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/stormshield/snmp/sn910
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All QoS are ok | 'BYPASS_HA#qos.traffic.in.peak.bitspersecond'=181144.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.peak.bitspersecond'=4248.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_ha2#qos.traffic.in.peak.bitspersecond'=153472.00b/s;;;0; 'BYPASS_ha2#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_out#qos.traffic.in.peak.bitspersecond'=10064.00b/s;;;0; 'BYPASS_out#qos.traffic.out.peak.bitspersecond'=213128.00b/s;;;0; 'BYPASS_in#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_in#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0;
    ...    2
    ...    ${EMPTY}
    ...    OK: All QoS are ok | 'BYPASS_HA#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.in.peak.bitspersecond'=181144.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.peak.bitspersecond'=4248.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_ha2#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_ha2#qos.traffic.in.peak.bitspersecond'=153472.00b/s;;;0; 'BYPASS_ha2#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_ha2#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_out#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_out#qos.traffic.in.peak.bitspersecond'=10064.00b/s;;;0; 'BYPASS_out#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_out#qos.traffic.out.peak.bitspersecond'=213128.00b/s;;;0; 'BYPASS_in#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_in#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_in#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_in#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0;
    ...    3
    ...    --warning-traffic-in-peak=150000
    ...    WARNING: QoS 'BYPASS_HA' traffic in peak: 181.14 Kb/s - QoS 'BYPASS_ha2' traffic in peak: 153.47 Kb/s | 'BYPASS_HA#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.in.peak.bitspersecond'=181144.00b/s;0:150000;;0; 'BYPASS_HA#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.peak.bitspersecond'=4248.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.in.peak.bitspersecond'=0.00b/s;0:150000;;0; 'BYPASS_dmz8#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.in.peak.bitspersecond'=0.00b/s;0:150000;;0; 'BYPASS_ipsec#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_ha2#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_ha2#qos.traffic.in.peak.bitspersecond'=153472.00b/s;0:150000;;0; 'BYPASS_ha2#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_ha2#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.in.peak.bitspersecond'=0.00b/s;0:150000;;0; 'BYPASS_client0#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.in.peak.bitspersecond'=0.00b/s;0:150000;;0; 'BYPASS_server0#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.in.peak.bitspersecond'=0.00b/s;0:150000;;0; 'BYPASS_client1#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.in.peak.bitspersecond'=0.00b/s;0:150000;;0; 'BYPASS_server1#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_out#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_out#qos.traffic.in.peak.bitspersecond'=10064.00b/s;0:150000;;0; 'BYPASS_out#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_out#qos.traffic.out.peak.bitspersecond'=213128.00b/s;;;0; 'BYPASS_in#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_in#qos.traffic.in.peak.bitspersecond'=0.00b/s;0:150000;;0; 'BYPASS_in#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_in#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.in.peak.bitspersecond'=0.00b/s;0:150000;;0; 'BYPASS_dmz7#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.out.peak.bitspersecond'=0.00b/s;;;0;
    ...    4
    ...    --critical-traffic-out-peak=200000
    ...    CRITICAL: QoS 'BYPASS_out' traffic out peak: 213.13 Kb/s | 'BYPASS_HA#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.in.peak.bitspersecond'=181144.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.peak.bitspersecond'=4248.00b/s;;0:200000;0; 'BYPASS_dmz8#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz8#qos.traffic.out.peak.bitspersecond'=0.00b/s;;0:200000;0; 'BYPASS_ipsec#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_ipsec#qos.traffic.out.peak.bitspersecond'=0.00b/s;;0:200000;0; 'BYPASS_ha2#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_ha2#qos.traffic.in.peak.bitspersecond'=153472.00b/s;;;0; 'BYPASS_ha2#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_ha2#qos.traffic.out.peak.bitspersecond'=0.00b/s;;0:200000;0; 'BYPASS_client0#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_client0#qos.traffic.out.peak.bitspersecond'=0.00b/s;;0:200000;0; 'BYPASS_server0#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_server0#qos.traffic.out.peak.bitspersecond'=0.00b/s;;0:200000;0; 'BYPASS_client1#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_client1#qos.traffic.out.peak.bitspersecond'=0.00b/s;;0:200000;0; 'BYPASS_server1#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_server1#qos.traffic.out.peak.bitspersecond'=0.00b/s;;0:200000;0; 'BYPASS_out#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_out#qos.traffic.in.peak.bitspersecond'=10064.00b/s;;;0; 'BYPASS_out#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_out#qos.traffic.out.peak.bitspersecond'=213128.00b/s;;0:200000;0; 'BYPASS_in#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_in#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_in#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_in#qos.traffic.out.peak.bitspersecond'=0.00b/s;;0:200000;0; 'BYPASS_dmz7#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.in.peak.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_dmz7#qos.traffic.out.peak.bitspersecond'=0.00b/s;;0:200000;0;
    ...    5
    ...    --include-name='^BYPASS_HA$'
    ...    OK: QoS 'BYPASS_HA' traffic-in : Buffer creation, traffic-in-prct : Buffer creation, traffic in peak: 181.14 Kb/s, traffic-out : Buffer creation, traffic-out-prct : Buffer creation, traffic out peak: 4.25 Kb/s | 'BYPASS_HA#qos.traffic.in.peak.bitspersecond'=181144.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.peak.bitspersecond'=4248.00b/s;;;0;
    ...    6
    ...    --include-name='^BYPASS_HA$' --speed-in=100 --speed-out=100
    ...    OK: QoS 'BYPASS_HA' traffic in: 0.00b/s (0.00% on 100.00Mb), traffic in peak: 181.14 Kb/s, traffic out: 0.00b/s (0.00% on 100.00Mb), traffic out peak: 4.25 Kb/s | 'BYPASS_HA#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.in.percentage'=0.00%;;;0;100 'BYPASS_HA#qos.traffic.in.peak.bitspersecond'=181144.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.percentage'=0.00%;;;0;100 'BYPASS_HA#qos.traffic.out.peak.bitspersecond'=4248.00b/s;;;0;
    ...    7
    ...    --filter-name='^BYPASS_HA$' --critical-traffic-in=@0
    ...    CRITICAL: QoS 'BYPASS_HA' traffic in: 0.00b/s (- on -) | 'BYPASS_HA#qos.traffic.in.bitspersecond'=0.00b/s;;@0:0;0; 'BYPASS_HA#qos.traffic.in.peak.bitspersecond'=181144.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.peak.bitspersecond'=4248.00b/s;;;0;
    ...    8
    ...    --include-name='^BYPASS_HA$' --speed-in=100 --warning-traffic-in-prct=@0
    ...    WARNING: QoS 'BYPASS_HA' traffic in: 0.00b/s (0.00% on 100.00Mb) | 'BYPASS_HA#qos.traffic.in.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.in.percentage'=0.00%;@0:0;;0;100 'BYPASS_HA#qos.traffic.in.peak.bitspersecond'=181144.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.bitspersecond'=0.00b/s;;;0; 'BYPASS_HA#qos.traffic.out.peak.bitspersecond'=4248.00b/s;;;0;
    ...    9
    ...    --exclude-name='^BYPASS_'
    ...    UNKNOWN: No QoS found.
    ...    10
    ...    --include-name=nomatch
    ...    UNKNOWN: No QoS found.
