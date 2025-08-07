*** Settings ***
Documentation       Check port Spanning Tree Protocol current state (BRIDGE-MIB).

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::aruba::aoscx::snmp::plugin

*** Test Cases ***
spanning-tree ${tc}
    [Tags]    network    spanning-tree
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=spanning-tree
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/aruba/aoscx/snmp/slim_aoscx-spanning-tree
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     ${EMPTY}                                                                                                OK: All spanning trees are ok
            ...      2     --filter-port='Anonymized 147'                                                                          OK: Port 'Anonymized 147' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '1']
            ...      3     --warning-status='\\\%{op_status} =~ /up/ && \\\%{state} =~ /forwarding/'                               WARNING: Port 'Anonymized 147' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '1'] - Port 'Anonymized 088' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '3'] - Port 'Anonymized 218' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '769']
            ...      4     --critical-status='\\\%{op_status} =~ /down/ && \\\%{state} =~ /blocking|broken/'                       CRITICAL: Port 'Anonymized 026' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '10'] - Port 'Anonymized 232' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '11'] - Port 'Anonymized 093' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '12'] - Port 'Anonymized 058' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '13'] - Port 'Anonymized 118' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '14'] - Port 'Anonymized 029' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '2'] - Port 'Anonymized 220' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '4'] - Port 'Anonymized 003' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '5'] - Port 'Anonymized 118' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '6'] - Port 'Anonymized 192' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '7'] - Port 'Anonymized 123' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '8'] - Port 'Anonymized 203' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '9']