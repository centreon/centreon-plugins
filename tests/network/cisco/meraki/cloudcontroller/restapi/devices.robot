*** Settings ***
Documentation       Meraki Devices

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}devices.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=network::cisco::meraki::cloudcontroller::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token=EEECGFCGFCGF


*** Test Cases ***
devices ${tc}
    [Tags]    meraki    api    devices    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=devices
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Device 'My AP' status: online - connection success: 40 - traffic traffic-in : Buffer creation, traffic-out : Buffer creation - link 'wan1' status: active | 'devices.total.online.count'=1;;;0;1 'devices.total.online.percentage'=100.00%;;;0;100 'devices.total.offline.count'=0;;;0;1 'devices.total.offline.percentage'=0.00%;;;0;100 'devices.total.alerting.count'=0;;;0;1 'DEVICESERIAL#device.connections.success.count'=40;;;0; 'DEVICESERIAL#device.connections.auth.count'=1;;;0; 'DEVICESERIAL#device.connections.assoc.count'=0;;;0; 'DEVICESERIAL#device.connections.dhcp.count'=0;;;0; 'DEVICESERIAL#device.connections.dns.count'=0;;;0; 'DEVICESERIAL#device.links.ineffective.count'=0;;;0;
    ...    2
    ...    ${EMPTY}
    ...    OK: Device 'My AP' status: online - connection success: 40 - traffic in: 59.00 Mb/s, out: 129.01 Mb/s - link 'wan1' status: active | 'devices.total.online.count'=1;;;0;1 'devices.total.online.percentage'=100.00%;;;0;100 'devices.total.offline.count'=0;;;0;1 'devices.total.offline.percentage'=0.00%;;;0;100 'devices.total.alerting.count'=0;;;0;1 'DEVICESERIAL#device.connections.success.count'=40;;;0; 'DEVICESERIAL#device.connections.auth.count'=1;;;0; 'DEVICESERIAL#device.connections.assoc.count'=0;;;0; 'DEVICESERIAL#device.connections.dhcp.count'=0;;;0; 'DEVICESERIAL#device.connections.dns.count'=0;;;0; 'DEVICESERIAL#device.traffic.in.bitspersecond'=59000000b/s;;;0; 'DEVICESERIAL#device.traffic.out.bitspersecond'=129008000b/s;;;0; 'DEVICESERIAL#device.links.ineffective.count'=0;;;0;
    ...    3
    ...    --warning-connections-success=5
    ...    WARNING: Device 'My AP' connection success: 40 | 'devices.total.online.count'=1;;;0;1 'devices.total.online.percentage'=100.00%;;;0;100 'devices.total.offline.count'=0;;;0;1 'devices.total.offline.percentage'=0.00%;;;0;100 'devices.total.alerting.count'=0;;;0;1 'DEVICESERIAL#device.connections.success.count'=40;0:5;;0; 'DEVICESERIAL#device.connections.auth.count'=1;;;0; 'DEVICESERIAL#device.connections.assoc.count'=0;;;0; 'DEVICESERIAL#device.connections.dhcp.count'=0;;;0; 'DEVICESERIAL#device.connections.dns.count'=0;;;0; 'DEVICESERIAL#device.traffic.in.bitspersecond'=444072000b/s;;;0; 'DEVICESERIAL#device.traffic.out.bitspersecond'=308280000b/s;;;0; 'DEVICESERIAL#device.links.ineffective.count'=0;;;0;
    ...    4
    ...    --critical-connections-success=5
    ...    CRITICAL: Device 'My AP' connection success: 40 | 'devices.total.online.count'=1;;;0;1 'devices.total.online.percentage'=100.00%;;;0;100 'devices.total.offline.count'=0;;;0;1 'devices.total.offline.percentage'=0.00%;;;0;100 'devices.total.alerting.count'=0;;;0;1 'DEVICESERIAL#device.connections.success.count'=40;;0:5;0; 'DEVICESERIAL#device.connections.auth.count'=1;;;0; 'DEVICESERIAL#device.connections.assoc.count'=0;;;0; 'DEVICESERIAL#device.connections.dhcp.count'=0;;;0; 'DEVICESERIAL#device.connections.dns.count'=0;;;0; 'DEVICESERIAL#device.traffic.in.bitspersecond'=25952000b/s;;;0; 'DEVICESERIAL#device.traffic.out.bitspersecond'=196912000b/s;;;0; 'DEVICESERIAL#device.links.ineffective.count'=0;;;0;
