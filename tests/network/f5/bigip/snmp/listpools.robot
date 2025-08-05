*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
list-pools ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-pools
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                           expected_result    --
            ...      1     ${EMPTY}                                                                List pools: [name: /Common/AN-577_pool] [status: green] [state: enabled] [name: /Common/ActiveDirectory_pool] [status: green] [state: enabled] [name: /Common/ActiveSync.app/ActiveSync_as_pool7] [status: green] [state: enabled] [name: /Common/ActiveSync_cert.app/ActiveSync_cert_as_pool7] [status: green] [state: enabled]
            ...      2     --filter-name='/Common/AN-577_pool'                                     List pools: [name: /Common/AN-577_pool] [status: green] [state: enabled]