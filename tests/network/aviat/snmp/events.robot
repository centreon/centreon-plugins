*** Settings ***
Documentation       network::aviat::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::aviat::snmp::plugin
...         --mode=events
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/aviat/snmp/aviat


*** Test Cases ***
Events ${tc}
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
    ...    OK: All slots are ok
    ...    2
    ...    --filter-slot-name=ANO1
    ...    OK: slot 'XXC ANO1'
    ...    3
    ...    --filter-event-severity=minor
    ...    OK: slot 'AAC ANO2'
    ...    4
    ...    --filter-event-name="NPC TDM clock failure"
    ...    OK: slot 'AAZ ANO5'
    ...    5
    ...    --unknown-status='\\\\%\\\\{count} > 0' --filter-slot-name=ANO1
    ...    UNKNOWN: slot 'XXC ANO1' event 'Terminal' count: 0 [severity: critical] | 'XXC ANO1~Terminal#event.detected.count'=0;;;;
    ...    6
    ...    --warning-status='\\\\%\\\\{count} > 0' --filter-slot-name=ANO1
    ...    WARNING: slot 'XXC ANO1' event 'Terminal' count: 0 [severity: critical] | 'XXC ANO1~Terminal#event.detected.count'=0;;;;
    ...    7
    ...    --critical-status='\\\\%\\\\{count} > 0' --filter-slot-name=ANO1
    ...    CRITICAL: slot 'XXC ANO1' event 'Terminal' count: 0 [severity: critical] | 'XXC ANO1~Terminal#event.detected.count'=0;;;;
