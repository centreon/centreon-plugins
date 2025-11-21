*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin


*** Test Cases ***
list-nodes ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-nodes
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                        expected_result    --
            ...      1     ${EMPTY}                                             List nodes: [name: /Common/172.20.15.202] [status: blue] [state: enabled] [name: /Common/172.20.2.117] [status: blue] [state: enabled] [name: /Common/172.20.2.127] [status: blue] [state: enabled] [name: /Common/172.20.2.132] [status: blue] [state: enabled]
            ...      2     --filter-name='toto'                                 List nodes:
