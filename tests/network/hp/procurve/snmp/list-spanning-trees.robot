*** Settings ***
Documentation       List ports using Spanning Tree Protocol.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::hp::procurve::snmp::plugin

*** Test Cases ***
list-spanning-trees ${tc}
    [Tags]    network    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-spanning-trees
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/hp/procurve/snmp/slim_procurve-spanning-tree
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
     Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                          expected_result    --
            ...      1     --filter-port='Anonymized 029'         List ports with spanning tree protocol: [port = Anonymized 029] [state = forwarding] [op_status = up] [admin_status = up] [index = 2]
