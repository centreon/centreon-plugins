*** Settings ***
Documentation       hardware::sensors::messpc::ethernetbox::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=hardware::sensors::messpc::ethernetbox::snmp::plugin
...         --mode=uptime
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=hardware/sensors/messpc/ethernetbox/snmp/ethernetbox


*** Test Cases ***
Uptime ${tc}
    [Tags]    hardware    sensors    snmp
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
    ...    OK: System uptime is: 70d 15h 23m 27s | 'system.uptime.seconds'=6103407.00s;;;0;
    ...    2
    ...    --warning-uptime=1
    ...    WARNING: System uptime is: 70d 15h 23m 27s | 'system.uptime.seconds'=6103407.00s;0:1;;0;
    ...    3
    ...    --critical-uptime=1
    ...    CRITICAL: System uptime is: 70d 15h 23m 27s | 'system.uptime.seconds'=6103407.00s;;0:1;0;
    ...    4
    ...    --add-sysdesc=1
    ...    OK: System uptime is: 70d 15h 23m 27s, Server Test, test v1.2.3 | 'system.uptime.seconds'=6103407.00s;;;0;
    ...    5
    ...    --check-overload=1
    ...    OK: System uptime is: 70d 15h 23m 27s | 'system.uptime.seconds'=6103407.00s;;;0;
    ...    6
    ...    --reboot-window=1
    ...    OK: System uptime is: 70d 15h 23m 27s | 'system.uptime.seconds'=6103407.00s;;;0;
