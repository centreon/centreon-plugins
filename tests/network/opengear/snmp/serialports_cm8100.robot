*** Settings ***
Documentation       network::opengear::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::opengear::snmp::plugin
...         --mode=serial-ports
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=2
...         --snmp-community=network/opengear/snmp/serialports_cm8100


*** Test Cases ***
Serialports CM8100 ${tc}
    [Tags]    network    opengear    snmp
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
    ...    OK: All interfaces are ok
    ...    2
    ...    --include-name=ANO02
    ...    OK: Serial port 'ANO02' traffic in: Buffer creation, traffic out: Buffer creation
    ...    3
    ...    --exclude-name=ANO02
    ...    OK: Serial port 'ANO01' traffic in: Buffer creation, traffic out: Buffer creation
    ...    4
    ...    --warning-traffic-in=1:
    ...    WARNING: Serial port 'ANO01' traffic in: 0.00b/s (0.00%) - Serial port 'ANO02' traffic in: 0.00b/s (0.00%) | 'ANO01#serial_port.traffic.in.bitspersecond'=0.00;96:;;0;9600 'ANO01#serial_port.traffic.out.bitspersecond'=0.00;;;0;9600 'ANO02#serial_port.traffic.in.bitspersecond'=0.00;1152:;;0;115200 'ANO02#serial_port.traffic.out.bitspersecond'=0.00;;;0;115200
    ...    5
    ...    --critical-traffic-in=1:
    ...    CRITICAL: Serial port 'ANO01' traffic in: 0.00b/s (0.00%) - Serial port 'ANO02' traffic in: 0.00b/s (0.00%) | 'ANO01#serial_port.traffic.in.bitspersecond'=0.00;;96:;0;9600 'ANO01#serial_port.traffic.out.bitspersecond'=0.00;;;0;9600 'ANO02#serial_port.traffic.in.bitspersecond'=0.00;;1152:;0;115200 'ANO02#serial_port.traffic.out.bitspersecond'=0.00;;;0;115200
    ...    6
    ...    --warning-traffic-out=1:
    ...    WARNING: Serial port 'ANO01' traffic out: 0.00b/s (0.00%) - Serial port 'ANO02' traffic out: 0.00b/s (0.00%) | 'ANO01#serial_port.traffic.in.bitspersecond'=0.00;;;0;9600 'ANO01#serial_port.traffic.out.bitspersecond'=0.00;96:;;0;9600 'ANO02#serial_port.traffic.in.bitspersecond'=0.00;;;0;115200 'ANO02#serial_port.traffic.out.bitspersecond'=0.00;1152:;;0;115200
    ...    7
    ...    --critical-traffic-out=1:
    ...    CRITICAL: Serial port 'ANO01' traffic out: 0.00b/s (0.00%) - Serial port 'ANO02' traffic out: 0.00b/s (0.00%) | 'ANO01#serial_port.traffic.in.bitspersecond'=0.00;;;0;9600 'ANO01#serial_port.traffic.out.bitspersecond'=0.00;;96:;0;9600 'ANO02#serial_port.traffic.in.bitspersecond'=0.00;;;0;115200 'ANO02#serial_port.traffic.out.bitspersecond'=0.00;;1152:;0;115200
    ...    8
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>name</element> </data>
    ...    9
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label name="ANO01"/> <label name="ANO02"/> </data>
