*** Settings ***
Documentation       network::kairos::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::kairos::snmp::plugin
...         --mode=list-alarms
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/kairos/snmp/kairos-ent


*** Test Cases ***
List-alarms ${tc}
    [Tags]    network    kairos    snmp
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
    ...    ^List alarms: \\\\n\\\\[name: IO1Contact\\\\]\\\\[instance: 1\\\\]
