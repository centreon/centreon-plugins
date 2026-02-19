*** Settings ***
Documentation       network::aviat::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::aviat::snmp::plugin
...         --mode=uptime
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/aviat/snmp/aviat


*** Test Cases ***
Uptime ${tc}
    [Tags]    network    aviat    snmp
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
    ...    OK: System uptime is: 33d 5h 54m 22s | 'system.uptime.seconds'=2872462.00s;;;0;
    ...    2
    ...    --warning-uptime=1
    ...    WARNING: System uptime is: 33d 5h 54m 22s | 'system.uptime.seconds'=2872462.00s;0:1;;0;
    ...    3
    ...    --critical-uptime=1
    ...    CRITICAL: System uptime is: 33d 5h 54m 22s | 'system.uptime.seconds'=2872462.00s;;0:1;0;
    ...    4
    ...    --add-sysdesc=1
    ...    OK: System uptime is: 33d 5h 54m 22s, - | 'system.uptime.seconds'=2872462.00s;;;0;
    ...    5
    ...    --force-oid=1
    ...    UNKNOWN: SNMP GET Request: Cant get a single value.
    ...    6
    ...    --check-overload=1
    ...    OK: System uptime is: 33d 5h 54m 22s | 'system.uptime.seconds'=2872462.00s;;;0;
    ...    7
    ...    --reboot-window=1
    ...    OK: System uptime is: 33d 5h 54m 22s | 'system.uptime.seconds'=2872462.00s;;;0;
