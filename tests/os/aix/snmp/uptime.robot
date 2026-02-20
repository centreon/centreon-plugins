*** Settings ***
Resource        ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup     Ctn Generic Suite Setup
Test Timeout    120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::aix::snmp::plugin


*** Test Cases ***
uptime ${tc}
    [Tags]    os    aix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=uptime
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/aix/snmp/aix
    ...    --snmp-timeout=5
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: System uptime is: 100d 22h 2m 45s | 'uptime'=8719365.00s;;;0;
    ...    2
    ...    --warning-uptime=5
    ...    WARNING: System uptime is: 100d 22h 2m 45s | 'uptime'=8719365.00s;0:5;;0;
    ...    3
    ...    --critical-uptime=4
    ...    CRITICAL: System uptime is: 100d 22h 2m 45s | 'uptime'=8719365.00s;;0:4;0;
    ...    4
    ...    --add-sysdesc
    ...    OK: System uptime is: 100d 22h 2m 45s, Anonymized 023Machine Type: 0x0800004c Processor id: 00C812714B00Base Operating System Runtime AIX version: 07.03.0002.0003TCP/IP Client Core Support version: 07.03.0002.0001 | 'uptime'=8719365.00s;;;0;
    ...    5
    ...    --check-overload
    ...    OK: System uptime is: 100d 22h 2m 45s | 'uptime'=8719365.00s;;;0;
    ...    6
    ...    --unit=h
    ...    OK: System uptime is: 100d 22h 2m 45s | 'uptime'=2422.05h;;;0;
    ...    7
    ...    --unit=d
    ...    OK: System uptime is: 100d 22h 2m 45s | 'uptime'=100.92d;;;0;
    ...    8
    ...    --unit=w
    ...    OK: System uptime is: 100d 22h 2m 45s | 'uptime'=14.42w;;;0;
