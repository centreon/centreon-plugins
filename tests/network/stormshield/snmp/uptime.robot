*** Settings ***
Documentation       network::stormshield::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::stormshield::snmp::plugin
...         --mode=uptime
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}
...         --snmp-community=network/stormshield/snmp/sn910


*** Test Cases ***
Uptime ${tc}
    [Tags]    network    stormshield    snmp
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
    ...    OK: Uptime: 71 days 20 hours 39 minutes 47 seconds | 'system.uptime.seconds'=6208787s;;;0;
    ...    2
    ...    --warning-uptime=1
    ...    WARNING: Uptime: 71 days 20 hours 39 minutes 47 seconds | 'system.uptime.seconds'=6208787s;0:1;;0;
    ...    3
    ...    --critical-uptime=1
    ...    CRITICAL: Uptime: 71 days 20 hours 39 minutes 47 seconds | 'system.uptime.seconds'=6208787s;;0:1;0;
    ...    4
    ...    --verbose
    ...    OK: Uptime: 71 days 20 hours 39 minutes 47 seconds | 'system.uptime.seconds'=6208787s;;;0; System Name: <fw_2> Model: SN910 Serial Number: <fw_1> Version: 5.2.0.dev Date: 2026-04-29 17:29:10 System Node Name: None Bios Version: 4.6.5
