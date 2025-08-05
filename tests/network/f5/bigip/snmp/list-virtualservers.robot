*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
list-virtualservers ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-virtualservers
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     ${EMPTY}                                                              List virtual servers: [name: /Common/ActiveSync.app/ActiveSync_combined_http] [status: blue] [state: enabled] [name: /Common/ActiveSync.app/ActiveSync_combined_https] [status: green] [state: enabled]
            ...      2     --filter-name='toto'                                                  List virtual servers: