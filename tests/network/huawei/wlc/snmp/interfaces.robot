*** Settings ***
Documentation       Check Huawei equipments in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::wlc::snmp::plugin


*** Test Cases ***
interfaces ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Run     ${command}
    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                        expected_result    --
            ...      1     --verbose                                                                                            CRITICAL: Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 221' Status : down (admin: up) - Interface 'Anonymized 003' Status : down (admin: up) - Interface 'Anonymized 232' Status : down (admin: up) - Interface 'Anonymized 109' Status : down (admin: up) - Interface 'Anonymized 034' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 016' Status : down (admin: up) - Interface 'Anonymized 214' Status : down (admin: up) - Interface 'Anonymized 118' Status : down (admin: up) - Interface 'Anonymized 039' Status : down (admin: up) - Interface 'Anonymized 180' Status : down (admin: up) - Interface 'Anonymized 164' Status : down (admin: up) - Interface 'Anonymized 082' Status : down (admin: up) - Interface 'Anonymized 149' Status : down (admin: up) - Interface 'Anonymized 144' Status : down (admin: up) - Interface 'Anonymized 052' Status : down (admin: up) - Interface 'Anonymized 126' Status : down (admin: up)
            ...      2     --name --interface='Anonymized 012'                                                                  CRITICAL: Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up)
            ...      3     --add-status --name --interface='Anonymized 012'                                                     CRITICAL: Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up)
            ...      4     --add-duplex-status --name --interface='Anonymized 012'                                              CRITICAL: Interface 'Anonymized 012' Status : down (admin: up) (duplex: n/a) - Interface 'Anonymized 012' Status : down (admin: up) (duplex: n/a) - Interface 'Anonymized 012' Status : down (admin: up) (duplex: n/a)
            ...      5     --add-speed --name --interface='Anonymized 012'                                                      CRITICAL: Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) | 'Anonymized 012#interface.speed.bitspersecond'=10000000000b/s;;;0; 'Anonymized 012#interface.speed.bitspersecond'=10000000000b/s;;;0; 'Anonymized 012#interface.speed.bitspersecond'=10000000000b/s;;;0;
            ...      6     --add-traffic --name --interface='Anonymized 012'                                                    OK: All interfaces are ok | 'Anonymized 012#interface.traffic.in.bitspersecond'=0.00b/s;;;0;10000000000 'Anonymized 012#interface.traffic.out.bitspersecond'=0.00b/s;;;0;10000000000 'Anonymized 012#interface.traffic.in.bitspersecond'=0.00b/s;;;0;10000000000 'Anonymized 012#interface.traffic.out.bitspersecond'=0.00b/s;;;0;10000000000 'Anonymized 012#interface.traffic.in.bitspersecond'=0.00b/s;;;0;10000000000 'Anonymized 012#interface.traffic.out.bitspersecond'=0.00b/s;;;0;10000000000
            ...      7     --add-volume --name --interface='Anonymized 012'                                                     CRITICAL: Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) | 'Anonymized 012#interface.volume.in.bytes'=0B;;;0; 'Anonymized 012#interface.volume.out.bytes'=0B;;;0; 'Anonymized 012#interface.volume.in.bytes'=0B;;;0; 'Anonymized 012#interface.volume.out.bytes'=0B;;;0; 'Anonymized 012#interface.volume.in.bytes'=0B;;;0; 'Anonymized 012#interface.volume.out.bytes'=0B;;;0;
            ...      8     --add-optical --name --interface='Anonymized 012'                                                    CRITICAL: Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) | 'Anonymized 012#interface.bias.current.milliampere'=-255mA;;;; 'Anonymized 012#interface.bias.current.milliampere'=-255mA;;;; 'Anonymized 012#interface.bias.current.milliampere'=-255mA;;;;
            ...      9     --add-traffic --name --interface='Anonymized 123' --speed=1                                          OK: Interface 'Anonymized 123' Traffic In : 0.00b/s (0.00%), Traffic Out : 0.00b/s (0.00%) | 'Anonymized 123#interface.traffic.in.bitspersecond'=0.00b/s;;;0;1000000 'Anonymized 123#interface.traffic.out.bitspersecond'=0.00b/s;;;0;1000000
            ...      10    --add-traffic --name --interface='Anonymized 123' --warning-in-traffic=1:1 --speed=1                 WARNING: Interface 'Anonymized 123' Traffic In : 0.00b/s (0.00%) | 'Anonymized 123#interface.traffic.in.bitspersecond'=0.00b/s;10000:10000;;0;1000000 'Anonymized 123#interface.traffic.out.bitspersecond'=0.00b/s;;;0;1000000
            ...      11    --add-traffic --name --interface='Anonymized 123' --critical-in-traffic=1:1 --speed-in=1             CRITICAL: Interface 'Anonymized 123' Traffic In : 0.00b/s (0.00%) | 'Anonymized 123#interface.traffic.in.bitspersecond'=0.00b/s;;10000:10000;0;1000000 'Anonymized 123#interface.traffic.out.bitspersecond'=0.00b/s;;;0;10000000000
            ...      12    --add-traffic --name --interface='Anonymized 123' --warning-out-traffic=1:1 --speed-out=1            WARNING: Interface 'Anonymized 123' Traffic Out : 0.00b/s (0.00%) | 'Anonymized 123#interface.traffic.in.bitspersecond'=0.00b/s;;;0;10000000000 'Anonymized 123#interface.traffic.out.bitspersecond'=0.00b/s;10000:10000;;0;1000000
            ...      13    --add-traffic --name --interface='Anonymized 123' --critical-out-traffic=1:1 --force-counters32      CRITICAL: Interface 'Anonymized 123' Traffic Out : 0.00b/s (0.00%) | 'Anonymized 123#interface.traffic.in.bitspersecond'=0.00b/s;;;0;4294967295 'Anonymized 123#interface.traffic.out.bitspersecond'=0.00b/s;;42949672:42949672;0;4294967295
            ...      14    --display-transform-src='Anonymized' --display-transform-dst='Interface' --name --interface='Anonymized 123'    OK: Interface 'Interface 123' Status : up (admin: up)
