*** Settings ***
Documentation       Meraki Devices

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Setup          CTN Cleanup Cache
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
    ...    OK: All devices are ok | 'devices.total.online.count'=2;;;0;2 'devices.total.online.percentage'=100.00%;;;0;100 'devices.total.offline.count'=0;;;0;2 'devices.total.offline.percentage'=0.00%;;;0;100 'devices.total.alerting.count'=0;;;0;2 'MGID#device.connections.success.count'=43;;;0; 'MGID#device.connections.auth.count'=1;;;0; 'MGID#device.connections.assoc.count'=0;;;0; 'MGID#device.connections.dhcp.count'=0;;;0; 'MGID#device.connections.dns.count'=0;;;0; 'MRID#device.connections.success.count'=40;;;0; 'MRID#device.connections.auth.count'=1;;;0; 'MRID#device.connections.assoc.count'=0;;;0; 'MRID#device.connections.dhcp.count'=0;;;0; 'MRID#device.connections.dns.count'=0;;;0;
    ...    2
    ...    --warning-connections-success=5
    ...    WARNING: Device 'My AP MG' connection success: 43 - Device 'My AP MR' connection success: 40 | 'devices.total.online.count'=2;;;0;2 'devices.total.online.percentage'=100.00%;;;0;100 'devices.total.offline.count'=0;;;0;2 'devices.total.offline.percentage'=0.00%;;;0;100 'devices.total.alerting.count'=0;;;0;2 'MGID#device.connections.success.count'=43;0:5;;0; 'MGID#device.connections.auth.count'=1;;;0; 'MGID#device.connections.assoc.count'=0;;;0; 'MGID#device.connections.dhcp.count'=0;;;0; 'MGID#device.connections.dns.count'=0;;;0; 'MRID#device.connections.success.count'=40;0:5;;0; 'MRID#device.connections.auth.count'=1;;;0; 'MRID#device.connections.assoc.count'=0;;;0; 'MRID#device.connections.dhcp.count'=0;;;0; 'MRID#device.connections.dns.count'=0;;;0;
    ...    3
    ...    --critical-connections-success=5
    ...    CRITICAL: Device 'My AP MG' connection success: 43 - Device 'My AP MR' connection success: 40 | 'devices.total.online.count'=2;;;0;2 'devices.total.online.percentage'=100.00%;;;0;100 'devices.total.offline.count'=0;;;0;2 'devices.total.offline.percentage'=0.00%;;;0;100 'devices.total.alerting.count'=0;;;0;2 'MGID#device.connections.success.count'=43;;0:5;0; 'MGID#device.connections.auth.count'=1;;;0; 'MGID#device.connections.assoc.count'=0;;;0; 'MGID#device.connections.dhcp.count'=0;;;0; 'MGID#device.connections.dns.count'=0;;;0; 'MRID#device.connections.success.count'=40;;0:5;0; 'MRID#device.connections.auth.count'=1;;;0; 'MRID#device.connections.assoc.count'=0;;;0; 'MRID#device.connections.dhcp.count'=0;;;0; 'MRID#device.connections.dns.count'=0;;;0;
    ...    4
    ...    --filter-device-name='devices'
    ...    UNKNOWN: no devices found
