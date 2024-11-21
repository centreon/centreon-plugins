*** Settings ***
Documentation       Network Fortinet Fortigate SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::fortinet::fortigate::snmp::plugin

*** Test Cases ***
Network Fortinet Fortigate SNMP list link monitor ${tc}
    [Documentation]    Network Fortinet Fortigate SNMP list-linkmonitors
    [Tags]    network    fortinet    fortigate    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-link-monitors
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/fortinet/fortigate/snmp/linkmonitor
    ...    --filter-state=${filterstate}
    ...    --filter-name=${filtername}
    ...    --filter-vdom=${filtervdom}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  filterstate          filtername         filtervdom        expected_result    --
            ...       1   ${EMPTY}             ${EMPTY}           ${EMPTY}          List link monitors: \n[Name = MonitorWAN1] [Vdom = root] [State = alive]\n[Name = MonitorWAN2] [Vdom = root] [State = alive]\n[Name = MonitorWAN3] [Vdom = root] [State = dead] 
            ...       2   ${EMPTY}             'MonitorWAN1'      ${EMPTY}          List link monitors: \n[Name = MonitorWAN1] [Vdom = root] [State = alive]
            ...       3   'alive'              ${EMPTY}           ${EMPTY}          List link monitors: \n[Name = MonitorWAN1] [Vdom = root] [State = alive]\n[Name = MonitorWAN2] [Vdom = root] [State = alive] 
            ...       4   ${EMPTY}             ${EMPTY}           'root'            List link monitors: \n[Name = MonitorWAN1] [Vdom = root] [State = alive]\n[Name = MonitorWAN2] [Vdom = root] [State = alive]\n[Name = MonitorWAN3] [Vdom = root] [State = dead] 
