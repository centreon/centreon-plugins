*** Settings ***
Documentation       Test Cisco RTT Controls
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin
...         --mode=ipsla
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}

*** Test Cases ***
Ipsla_without ${tc}
    [Tags]    network    cisco    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/cisco/standard/snmp/ipsla-without-echoadminprecision
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                 expected_result    --
    ...          1     ${EMPTY}                                      OK: RTT 'tagname' Completion Time : 10 | 'completion_time'=10;;;0
    ...          2     --filter-tag=none                             UNKNOWN: No entry found.
    ...          3     --critical-CompletionTime=:5                  CRITICAL: RTT 'tagname' Completion Time : 10 | 'completion_time'=10;;0:5;0;
    ...          4     --warning-CompletionTime=:5                   WARNING: RTT 'tagname' Completion Time : 10 | 'completion_time'=10;0:5;;0;

Ipsla_without ${tc}
    [Tags]    network    cisco    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/cisco/standard/snmp/ipsla-with-echoadminprecision
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                 expected_result    --
    ...          1     ${EMPTY}                                      OK: RTT 'tagname' Completion Time : 10 | 'completion_time'=10;;;0
    ...          2     --filter-tag=none                             UNKNOWN: No entry found.
    ...          3     --critical-CompletionTime=:5                  CRITICAL: RTT 'tagname' Completion Time : 10 | 'completion_time'=10;;0:5;0;
    ...          4     --warning-CompletionTime=:5                   WARNING: RTT 'tagname' Completion Time : 10 | 'completion_time'=10;0:5;;0;
