*** Settings ***
Documentation       List ports using Spanning Tree Protocol.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::aruba::aoscx::snmp::plugin

*** Test Cases ***
list-spanning-trees ${tc}
    [Tags]    network    aruba
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-spanning-trees
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/aruba/aoscx/snmp/slim_aoscx-spanning-tree
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                      expected_result    --
            ...      1     ${EMPTY}                           List ports with spanning tree protocol: [port = Anonymized 147] [state = forwarding] [op_status = up] [admin_status = up] [index = 1] [port = Anonymized 026] [state = blocking] [op_status = down] [admin_status = up] [index = 10] [port = Anonymized 232] [state = blocking] [op_status = down] [admin_status = up] [index = 11] [port = Anonymized 093] [state = blocking] [op_status = down] [admin_status = up] [index = 12] [port = Anonymized 058] [state = blocking] [op_status = down] [admin_status = up] [index = 13] [port = Anonymized 118] [state = blocking] [op_status = down] [admin_status = up] [index = 14] [port = Anonymized 029] [state = blocking] [op_status = down] [admin_status = up] [index = 2] [port = Anonymized 088] [state = forwarding] [op_status = up] [admin_status = up] [index = 3] [port = Anonymized 220] [state = blocking] [op_status = down] [admin_status = up] [index = 4] [port = Anonymized 003] [state = blocking] [op_status = down] [admin_status = up] [index = 5] [port = Anonymized 118] [state = blocking] [op_status = down] [admin_status = up] [index = 6] [port = Anonymized 192] [state = blocking] [op_status = down] [admin_status = up] [index = 7] [port = Anonymized 218] [state = forwarding] [op_status = up] [admin_status = up] [index = 769] [port = Anonymized 123] [state = blocking] [op_status = down] [admin_status = up] [index = 8] [port = Anonymized 203] [state = blocking] [op_status = down] [admin_status = up] [index = 9]
            ...      2     --filter-port='Anonymized 147'     List ports with spanning tree protocol: [port = Anonymized 147] [state = forwarding] [op_status = up] [admin_status = up] [index = 1]