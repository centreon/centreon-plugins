*** Settings ***
Documentation       List ports using Spanning Tree Protocol.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

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
 
    # first run to build cache
    Run    ${command}
    # second run to control the output
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     --filter-port='Anonymized 053'                                                                          List ports with spanning tree protocol: [port = Anonymized 053] [state = forwarding] [op_status = up] [admin_status = up] [index = 28]
            ...      2     --filter-port                                                                                           List ports with spanning tree protocol: [port = Anonymized 147] [state = blocking] [op_status = down] [admin_status = up] [index = 1] [port = Anonymized 026] [state = blocking] [op_status = down] [admin_status = up] [index = 10] [port = Anonymized 232] [state = blocking] [op_status = down] [admin_status = up] [index = 11] [port = Anonymized 093] [state = blocking] [op_status = down] [admin_status = up] [index = 12] [port = Anonymized 058] [state = blocking] [op_status = down] [admin_status = up] [index = 13] [port = Anonymized 118] [state = blocking] [op_status = down] [admin_status = up] [index = 14] [port = Anonymized 158] [state = blocking] [op_status = down] [admin_status = up] [index = 15] [port = Anonymized 191] [state = blocking] [op_status = down] [admin_status = up] [index = 16] [port = Anonymized 160] [state = blocking] [op_status = down] [admin_status = up] [index = 17] [port = Anonymized 188] [state = blocking] [op_status = down] [admin_status = up] [index = 18] [port = Anonymized 034] [state = blocking] [op_status = down] [admin_status = up] [index = 19] [port = Anonymized 029] [state = forwarding] [op_status = up] [admin_status = up] [index = 2] [port = Anonymized 203] [state = forwarding] [op_status = up] [admin_status = up] [index = 20] [port = Anonymized 054] [state = blocking] [op_status = down] [admin_status = up] [index = 21] [port = Anonymized 189] [state = blocking] [op_status = down] [admin_status = up] [index = 22] [port = Anonymized 056] [state = forwarding] [op_status = up] [admin_status = up] [index = 23] [port = Anonymized 204] [state = blocking] [op_status = down] [admin_status = up] [index = 24] [port = Anonymized 026] [state = blocking] [op_status = down] [admin_status = up] [index = 25] [port = Anonymized 135] [state = blocking] [op_status = down] [admin_status = up] [index = 26] [port = Anonymized 182] [state = blocking] [op_status = down] [admin_status = up] [index = 27] [port = Anonymized 053] [state = forwarding] [op_status = up] [admin_status = up] [index = 28] [port = Anonymized 088] [state = blocking] [op_status = down] [admin_status = up] [index = 3] [port = Anonymized 220] [state = blocking] [op_status = down] [admin_status = up] [index = 4] [port = Anonymized 003] [state = blocking] [op_status = down] [admin_status = up] [index = 5] [port = Anonymized 118] [state = blocking] [op_status = down] [admin_status = up] [index = 6] [port = Anonymized 192] [state = blocking] [op_status = down] [admin_status = up] [index = 7] [port = Anonymized 123] [state = forwarding] [op_status = up] [admin_status = up] [index = 8] [port = Anonymized 203] [state = blocking] [op_status = down] [admin_status = up] [index = 9]