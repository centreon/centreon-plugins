*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
list-trunks ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-trunks
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                     expected_result    --
            ...      1     ${EMPTY}                          List trunks: 'Anonymized 234' [status: up] [speed: 20000]
            ...      2     --filter-name='toto'              List trunks: 'Anonymized 234' [status: up] [speed: 20000]    #filter not working 
