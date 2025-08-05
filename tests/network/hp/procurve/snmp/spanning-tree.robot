*** Settings ***
Documentation       Check port Spanning Tree Protocol current state (BRIDGE-MIB).

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::hp::procurve::snmp::plugin

*** Test Cases ***
spanning-tree ${tc}
    [Tags]    network    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=spanning-tree
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/hp/procurve/snmp/slim_procurve-spanning-tree
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                  expected_result    --
            ...      1     ${EMPTY}                                                       OK: All spanning trees are ok
            ...      2     --filter-port='Anonymized 147'                                 OK: Port 'Anonymized 147' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '1']
            ...      3     --warning-status='\\\%{op_status} ne "up"'                     WARNING: Port 'Anonymized 147' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '1'] - Port 'Anonymized 088' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '3'] - Port 'Anonymized 220' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '4']
            ...      4     --critical-status='\\\%{op_status} ne "up"'                    CRITICAL: Port 'Anonymized 147' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '1'] - Port 'Anonymized 088' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '3'] - Port 'Anonymized 220' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '4']
            ...      5     --warning-status='\\\%{admin_status} eq "up"'                  WARNING: Port 'Anonymized 147' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '1'] - Port 'Anonymized 029' spanning tree state is 'forwarding' [op status: 'up'] [admin status: 'up'] [index: '2'] - Port 'Anonymized 088' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '3'] - Port 'Anonymized 220' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '4']
            ...      6     --critical-status='\\\%{op_status} eq "down"'                  CRITICAL: Port 'Anonymized 147' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '1'] - Port 'Anonymized 088' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '3'] - Port 'Anonymized 220' spanning tree state is 'blocking' [op status: 'down'] [admin status: 'up'] [index: '4']