*** Settings ***
Documentation       apps::thales::mistral::vs9::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mistral-mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::thales::mistral::vs9::restapi::plugin
...                 --mode=devices
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=1
...                 --api-password=1


*** Test Cases ***
Devices ${tc}
    [Tags]    apps    thales    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_regexp
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All devices are ok \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.connection.last.time.seconds'=\\\\d+s;;;0; 'DASERIAL#device.connection.last.time.seconds'=\\\\d+;;;0;
    ...    2
    ...    --filter-id=471
    ...    OK: device 'DASERIAL' connection status: connected, last connection: \\\\d+M \\\\d+d \\\\d+h \\\\d+m \\\\d+s \\\| 'devices.detected.count'=1;;;0; 'DASERIAL#device.connection.last.time.seconds'=\\\\d+s;;;0;
    ...    3
    ...    --filter-sn=DASERIAL
    ...    OK: device 'DASERIAL' connection status: connected, last connection: \\\\d+M \\\\d+d \\\\d+h \\\\d+m \\\\d+s \\\| 'devices.detected.count'=1;;;0; 'DASERIAL#device.connection.last.time.seconds'=\\\\d+s;;;0;
    ...    4
    ...    --filter-cert-revoked=1 --add-certificates
    ...    OK: All devices are ok \\\| 'devices.detected.count'=2;;;0;
    ...    5
    ...    --add-status
    ...    OK: All devices are ok \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.connection.last.time.seconds'=5510508s;;;0; 'DASERIAL#device.connection.last.time.seconds'=5510508s;;;0;
    ...    6
    ...    --add-interfaces
    ...    OK: All devices are ok \\\| 'devices.detected.count'=2;;;0; '987654.000001~blk1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~blk1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 '987654.000001~red1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~red1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 '987654.000001~redsfp1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~redsfp1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~blk1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~blk1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~red1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~red1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~redsfp1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~redsfp1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000
    ...    7
    ...    --add-system
    ...    OK: All devices are ok \\\| 'devices.detected.count'=2;;;0; '987654.000001#system.uptime.seconds'=6047707s;;;0; '987654.000001#system.time.offset.seconds'=-5510700s;;;; 'DASERIAL#system.uptime.seconds'=6047707s;;;0; 'DASERIAL#system.time.offset.seconds'=-5510700s;;;;
    ...    8
    ...    --add-mistral
    ...    OK: All devices are ok \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.temperature.celsius'=58C;;;; 'DASERIAL#device.temperature.celsius'=58C;;;;
    ...    9
    ...    --add-certificates
    ...    OK: All devices are ok \\\| 'devices.detected.count'=2;;;0;
    ...    10
    ...    --add-tunnels
    ...    OK: All devices are ok \\\| 'devices.detected.count'=2;;;0; '987654.000001~-1052062677_41_100.100.100.10.inbound(src:10.10.20.0/24,dst:10.10.100.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-1052062677_41_100.100.20.10.outbound(src:10.10.100.0/24,dst:10.10.20.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-1611793448_44_100.100.100.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-1611793448_44_100.100.200.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-1622882490_42_100.100.100.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-1622882490_42_100.100.30.10.outbound(src:10.10.100.100/32,dst:10.10.20.20/32)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-1683044391_44_100.100.100.10.inbound(src:192.168.200.100/32,dst:10.10.100.100/32)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-1683044391_44_100.100.200.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-2102713877_44_100.100.100.10.inbound(src:192.168.200.0/24,dst:192.168.100.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-2102713877_44_100.100.200.10.outbound(src:192.168.100.0/24,dst:192.168.200.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-82481654_42_100.100.100.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-82481654_42_100.100.30.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~415173799_41_100.100.100.10.inbound(src:10.10.20.10/32,dst:10.10.100.100/32)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~415173799_41_100.100.20.10.outbound(src:10.10.100.100/32,dst:10.10.20.10/32)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~804296985_44_100.100.100.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~804296985_44_100.100.200.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-1052062677_41_100.100.100.10.inbound(src:10.10.20.0/24,dst:10.10.100.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-1052062677_41_100.100.20.10.outbound(src:10.10.100.0/24,dst:10.10.20.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-1611793448_44_100.100.100.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-1611793448_44_100.100.200.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-1622882490_42_100.100.100.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-1622882490_42_100.100.30.10.outbound(src:10.10.100.100/32,dst:10.10.20.20/32)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-1683044391_44_100.100.100.10.inbound(src:192.168.200.100/32,dst:10.10.100.100/32)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-1683044391_44_100.100.200.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-2102713877_44_100.100.100.10.inbound(src:192.168.200.0/24,dst:192.168.100.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-2102713877_44_100.100.200.10.outbound(src:192.168.100.0/24,dst:192.168.200.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-82481654_42_100.100.100.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~-82481654_42_100.100.30.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~415173799_41_100.100.100.10.inbound(src:10.10.20.10/32,dst:10.10.100.100/32)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~415173799_41_100.100.20.10.outbound(src:10.10.100.100/32,dst:10.10.20.10/32)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~804296985_44_100.100.100.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0; 'DASERIAL~804296985_44_100.100.200.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0;
    ...    11
    ...    --critical-temperature=1 --add-mistral
    ...    CRITICAL: device '987654.000001' temperature: 58.00 C - device 'DASERIAL' temperature: 58.00 C \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.temperature.celsius'=58C;;0:1;; 'DASERIAL#device.temperature.celsius'=58C;;0:1;
    ...    12
    ...    --warning-vpn-sa-traffic=1: --add-tunnels
    ...    WARNING: device '987654.000001' vpn sa '-1052062677_41_100.100.100.10.inbound
    ...    13
    ...    --critical-vpn-sa-traffic=1: --add-tunnels
    ...    CRITICAL: device '987654.000001' vpn sa '-1052062677_41_100.100.100.10.inbound
    ...    14
    ...    --unknown-connection-status=1 --add-status
    ...    UNKNOWN: device '987654.000001' connection status: connected - device 'DASERIAL' connection status: connected \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.connection.last.time.seconds'=5514741s;;;0; 'DASERIAL#device.connection.last.time.seconds'=5514741s;;;0;
    ...    15
    ...    --warning-connection-status=1 --add-status
    ...    WARNING: device '987654.000001' connection status: connected - device 'DASERIAL' connection status: connected \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.connection.last.time.seconds'=5514741s;;;0; 'DASERIAL#device.connection.last.time.seconds'=5514741s;;;0;
    ...    16
    ...    --critical-connection-status=1 --add-status
    ...    CRITICAL: device '987654.000001' connection status: connected - device 'DASERIAL' connection status: connected \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.connection.last.time.seconds'=5514741s;;;0; 'DASERIAL#device.connection.last.time.seconds'=5514741s;;;0;
    ...    17
    ...    --unknown-operating-state='\\\%{operatingState} =~ /operating/i' --add-mistral
    ...    UNKNOWN: device '987654.000001' operating state: operating - device 'DASERIAL' operating state: operating \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.temperature.celsius'=58C;;;; 'DASERIAL#device.temperature.celsius'=58C;;;;
    ...    18
    ...    --warning-operating-state='\\\%{operatingState} =~ /operating/i' --add-mistral
    ...    WARNING: device '987654.000001' operating state: operating - device 'DASERIAL' operating state: operating \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.temperature.celsius'=58C;;;; 'DASERIAL#device.temperature.celsius'=58C;;;;
    ...    19
    ...    --critical-operating-state='\\\%{operatingState} =~ /operating/i' --add-mistral
    ...    CRITICAL: device '987654.000001' operating state: operating - device 'DASERIAL' operating state: operating \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.temperature.celsius'=58C;;;; 'DASERIAL#device.temperature.celsius'=58C;;;;
    ...    20
    ...    --unknown-autotest-state=1 --add-mistral
    ...    UNKNOWN: device '987654.000001' autotest 'Crypto(IPsec)' state: success - autotest 'Crypto(TLS,IKE)' state: success - autotest 'Log' state: success - device 'DASERIAL' autotest 'Crypto(IPsec)' state: success - autotest 'Crypto(TLS,IKE)' state: success - autotest 'Log' state: success \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.temperature.celsius'=58C;;;; 'DASERIAL#device.temperature.celsius'=58C;;;;
    ...    21
    ...    --warning-autotest-state=1 --add-mistral
    ...    WARNING: device '987654.000001' autotest 'Crypto(IPsec)' state: success - autotest 'Crypto(TLS,IKE)' state: success - autotest 'Log' state: success - device 'DASERIAL' autotest 'Crypto(IPsec)' state: success - autotest 'Crypto(TLS,IKE)' state: success - autotest 'Log' state: success \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.temperature.celsius'=58C;;;; 'DASERIAL#device.temperature.celsius'=58C;;;;
    ...    22
    ...    --critical-autotest-state=1 --add-mistral
    ...    CRITICAL: device '987654.000001' autotest 'Crypto(IPsec)' state: success - autotest 'Crypto(TLS,IKE)' state: success - autotest 'Log' state: success - device 'DASERIAL' autotest 'Crypto(IPsec)' state: success - autotest 'Crypto(TLS,IKE)' state: success - autotest 'Log' state: success \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.temperature.celsius'=58C;;;; 'DASERIAL#device.temperature.celsius'=58C;;;;
    ...    23
    ...    --unknown-interface-status=1 --add-interfaces
    ...    UNKNOWN: device '987654.000001' interface 'blk1' operating status: UP - interface 'red1' operating status: UP - interface 'redsfp1' operating status: UP - device 'DASERIAL' interface 'blk1' operating status: UP - interface 'red1' operating status: UP - interface 'redsfp1' operating status: UP \\\| 'devices.detected.count'=2;;;0; '987654.000001~blk1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~blk1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 '987654.000001~red1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~red1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 '987654.000001~redsfp1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~redsfp1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~blk1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~blk1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~red1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~red1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~redsfp1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~redsfp1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000
    ...    24
    ...    --warning-interface-status=1 --add-interfaces
    ...    WARNING: device '987654.000001' interface 'blk1' operating status: UP - interface 'red1' operating status: UP - interface 'redsfp1' operating status: UP - device 'DASERIAL' interface 'blk1' operating status: UP - interface 'red1' operating status: UP - interface 'redsfp1' operating status: UP \\\| 'devices.detected.count'=2;;;0; '987654.000001~blk1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~blk1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 '987654.000001~red1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~red1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 '987654.000001~redsfp1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~redsfp1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~blk1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~blk1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~red1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~red1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~redsfp1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~redsfp1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000
    ...    25
    ...    --critical-interface-status=1 --add-interfaces
    ...    CRITICAL: device '987654.000001' interface 'blk1' operating status: UP - interface 'red1' operating status: UP - interface 'redsfp1' operating status: UP - device 'DASERIAL' interface 'blk1' operating status: UP - interface 'red1' operating status: UP - interface 'redsfp1' operating status: UP \\\| 'devices.detected.count'=2;;;0; '987654.000001~blk1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~blk1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 '987654.000001~red1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~red1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 '987654.000001~redsfp1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~redsfp1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~blk1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~blk1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~red1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~red1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~redsfp1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~redsfp1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000
    ...    26
    ...    --unknown-vpn-ike-service-state=1 --add-tunnels
    ...    UNKNOWN: device '987654.000001' vpn ike service state: running - device 'DASERIAL' vpn ike service state: running \\\| 'devices.detected.count'=2;;;0; '987654.000001~-1052062677_41_100.100.100.10.inbound(src:10.10.20.0/24,dst:10.10.100.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0;
    ...    27
    ...    --warning-vpn-ike-service-state=1 --add-tunnels
    ...    WARNING: device '987654.000001' vpn ike service state: running - device 'DASERIAL' vpn ike service state: running \\\| 'devices.detected.count'=2;;;0; '987654.000001~-1052062677_41_100.100.100.10.inbound(src:10.10.20.0/24,dst:10.10.100.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-1052062677_41_100.100.20.10.outbound(src:10.10.100.0/24,dst:10.10.20.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0; '987654.000001~-1611793448_44_100.100.100.10#vpn.sa.traffic.bitspersecond'=0b/s;;;0;
    ...    28
    ...    --critical-vpn-ike-service-state=1 --add-tunnels
    ...    CRITICAL: device '987654.000001' vpn ike service state: running - device 'DASERIAL' vpn ike service state: running \\\| 'devices.detected.count'=2;;;0; '987654.000001~-1052062677_41_100.100.100.10.inbound(src:10.10.20.0/24,dst:10.10.100.0/24)#vpn.sa.traffic.bitspersecond'=0b/s;;;0;
    ...    29
    ...    --unknown-vpn-ike-sa-state=1 --add-tunnels
    ...    UNKNOWN: device '987654.000001' vpn ike sa '-1770408719_42' vpn state: established - vpn ike sa '-1801428527_41' vpn state: established - vpn ike sa '-1877415198_45' vpn state: connecting - vpn ike sa '108184537_44' vpn state: established - device 'DASERIAL' vpn ike sa '-1770408719_42' vpn state: established - vpn ike sa '-1801428527_41' vpn state: established - vpn ike sa '-1877415198_45' vpn state: connecting - vpn ike sa '108184537_44' vpn state: established \\\| 'devices.detected.count'=2;;;0;
    ...    30
    ...    --warning-vpn-ike-sa-state=1 --add-tunnels
    ...    WARNING: device '987654.000001' vpn ike sa '-1770408719_42' vpn state: established - vpn ike sa '-1801428527_41' vpn state: established - vpn ike sa '-1877415198_45' vpn state: connecting - vpn ike sa '108184537_44' vpn state: established - device 'DASERIAL' vpn ike sa '-1770408719_42' vpn state: established - vpn ike sa '-1801428527_41' vpn state: established - vpn ike sa '-1877415198_45' vpn state: connecting - vpn ike sa '108184537_44' vpn state: established
    ...    31
    ...    --critical-vpn-ike-sa-state=1 --add-tunnels
    ...    CRITICAL: device '987654.000001' vpn ike sa '-1770408719_42' vpn state: established - vpn ike sa '-1801428527_41' vpn state: established - vpn ike sa '-1877415198_45' vpn state: connecting - vpn ike sa '108184537_44' vpn state: established - device 'DASERIAL' vpn ike sa '-1770408719_42' vpn state: established - vpn ike sa '-1801428527_41' vpn state: established - vpn ike sa '-1877415198_45' vpn state: connecting - vpn ike sa '108184537_44' vpn state: established
    ...    32
    ...    --unknown-vpn-sa-state=1 --add-tunnels
    ...    UNKNOWN: device '987654.000001' vpn sa '-1052062677_41_100.100.100.10.inbound
    ...    33
    ...    --warning-vpn-sa-state=1 --add-tunnels
    ...    WARNING: device '987654.000001' vpn sa '-1052062677_41_100.100.100.10.inbound
    ...    34
    ...    --critical-vpn-sa-state=1 --add-tunnels
    ...    CRITICAL: device '987654.000001' vpn sa '-1052062677_41_100.100.100.10.inbound
    ...    35
    ...    --ntp-hostname=1
    ...    OK: All devices are ok \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.connection.last.time.seconds'=5515727s;;;0; 'DASERIAL#device.connection.last.time.seconds'=5515727s;;;0;
    ...    36
    ...    --ntp-port=1
    ...    OK: All devices are ok \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.connection.last.time.seconds'=5515727s;;;0; 'DASERIAL#device.connection.last.time.seconds'=5515727s;;;0;
    ...    37
    ...    --time-connection-unit=m
    ...    OK: All devices are ok | 'devices.detected.count'=2;;;0; '987654.000001#device.connection.last.time.minutes'=91929m;;;0; 'DASERIAL#device.connection.last.time.minutes'=91929m;;;0;
    ...    38
    ...    --time-uptime-unit=m --add-system
    ...    OK: All devices are ok | 'devices.detected.count'=2;;;0; '987654.000001#system.uptime.minutes'=100880m;;;0; '987654.000001#system.time.offset.seconds'=-5515837s;;;; 'DASERIAL#system.uptime.minutes'=100880m;;;0; 'DASERIAL#system.time.offset.seconds'=-5515837s;;;;
    ...    39
    ...    --time-certificate-unit=m --add-certificates
    ...    OK: All devices are ok | 'devices.detected.count'=2;;;0;
    ...    40
    ...    --traffic-unit=bps --add-interfaces
    ...    OK: All devices are ok | 'devices.detected.count'=2;;;0; '987654.000001~blk1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~blk1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 '987654.000001~red1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~red1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 '987654.000001~redsfp1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 '987654.000001~redsfp1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~blk1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~blk1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~red1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~red1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~redsfp1#interface.traffic.in.bitspersecond'=0.00;;;0;1000000000 'DASERIAL~redsfp1#interface.traffic.out.bitspersecond'=0.00;;;0;1000000000
    ...    41
    ...    --warning-devices-detected=1
    ...    WARNING: Number of devices detected: 2 \\\| 'devices.detected.count'=2;0:1;;0; '987654.000001#device.connection.last.time.seconds'=\\\\d+s;;;0; 'DASERIAL#device.connection.last.time.seconds'=\\\\d+s;;;0;
    ...    42
    ...    --critical-devices-detected=1
    ...    CRITICAL: Number of devices detected: 2 \\\| 'devices.detected.count'=2;;0:1;0; '987654.000001#device.connection.last.time.seconds'=\\\\d+s;;;0; 'DASERIAL#device.connection.last.time.seconds'=\\\\d+s;;;0;
    ...    43
    ...    --warning-connection-last-time=1 --add-status
    ...    WARNING: device '987654.000001' last connection: \\\\d+M \\\\d+d \\\\d+h \\\\d+m \\\\d+s - device 'DASERIAL' last connection: \\\\d+M \\\\d+d \\\\d+h \\\\d+m \\\\d+s \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.connection.last.time.seconds'=\\\\d+s;0:1;;0; 'DASERIAL#device.connection.last.time.seconds'=\\\\d+s;0:1;;0;
    ...    44
    ...    --critical-connection-last-time=1 --add-status
    ...    CRITICAL: device '987654.000001' last connection: \\\\d+M \\\\d+d \\\\d+h \\\\d+m \\\\d+s - device 'DASERIAL' last connection: \\\\d+M \\\\d+d \\\\d+h \\\\d+m \\\\d+s \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.connection.last.time.seconds'=\\\\d+s;;0:1;0; 'DASERIAL#device.connection.last.time.seconds'=\\\\d+s;;0:1;0;
    ...    45
    ...    --warning-interface-traffic-in=1: --add-interfaces
    ...    WARNING: device '987654.000001' interface 'blk1' traffic in: 0.00b/s
    ...    46
    ...    --critical-interface-traffic-in=1: --add-interfaces
    ...    CRITICAL: device '987654.000001' interface 'blk1' traffic in: 0.00b/s
    ...    47
    ...    --warning-interface-traffic-out=1: --add-interfaces
    ...    WARNING: device '987654.000001' interface 'blk1' traffic out: 0.00b/s
    ...    48
    ...    --critical-interface-traffic-out=1: --add-interfaces
    ...    CRITICAL: device '987654.000001' interface 'blk1' traffic out: 0.00b/s
    ...    49
    ...    --warning-system-uptime=1 --add-system
    ...    WARNING: device '987654.000001' uptime: \\\\d+d \\\\d+h \\\\d+m \\\\d+s - device 'DASERIAL' uptime: \\\\d+d \\\\d+h \\\\d+m \\\\d+s \\\| 'devices.detected.count'=2;;;0; '987654.000001#system.uptime.seconds'=\\\\d+s;0:1;;0; '987654.000001#system.time.offset.seconds'=-\\\\d+s;;;; 'DASERIAL#system.uptime.seconds'=\\\\d+s;0:1;;0; 'DASERIAL#system.time.offset.seconds'=-\\\\d+s;;;;
    ...    50
    ...    --critical-system-uptime=1 --add-system
    ...    CRITICAL: device '987654.000001' uptime: \\\\d+d \\\\d+h \\\\d+m \\\\d+s - device 'DASERIAL' uptime: \\\\d+d \\\\d+h \\\\d+m \\\\d+s \\\| 'devices.detected.count'=2;;;0; '987654.000001#system.uptime.seconds'=\\\\d+s;;0:1;0; '987654.000001#system.time.offset.seconds'=-\\\\d+s;;;; 'DASERIAL#system.uptime.seconds'=\\\\d+s;;0:1;0; 'DASERIAL#system.time.offset.seconds'=-\\\\d+s;;;;
    ...    51
    ...    --warning-system-time-offset=1 --add-system
    ...    WARNING: device '987654.000001' time offset
    ...    52
    ...    --critical-system-time-offset=1 --add-system
    ...    CRITICAL: device '987654.000001' time offset
    ...    53
    ...    --warning-temperature=1 --add-mistral
    ...    WARNING: device '987654.000001' temperature: 58.00 C - device 'DASERIAL' temperature: 58.00 C \\\| 'devices.detected.count'=2;;;0; '987654.000001#device.temperature.celsius'=58C;0:1;;; 'DASERIAL#device.temperature.celsius'=58C;0:1;;;
