*** Settings ***
Documentation       Check Aruba CX series in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::aruba::aoscx::snmp::plugin


*** Test Cases ***
list-interfaces ${tc}
    [Tags]    network    aruba    list-interfaces
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/aruba/aoscx/snmp/slim_aoscx-spanning-tree
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                  expected_result    --
            ...      1     --add-extra-oid='alias,.1.3.6.1.2.1.31.1.1.1.18'                               List interfaces: '1/1/1' [speed = 100][status = up][id = 1][alias = ][type = ethernetCsmacd] '1/1/10' [speed = ][status = down][id = 10][alias = ][type = ethernetCsmacd] '1/1/11' [speed = ][status = down][id = 11][alias = ][type = ethernetCsmacd] '1/1/12' [speed = ][status = down][id = 12][alias = ][type = ethernetCsmacd] '1/1/13' [speed = ][status = down][id = 13][alias = ][type = ethernetCsmacd] '1/1/14' [speed = ][status = down][id = 14][alias = ][type = ethernetCsmacd] '1/1/15' [speed = 1000][status = up][id = 15][alias = ][type = ethernetCsmacd] '1/1/16' [speed = 1000][status = up][id = 16][alias = ][type = ethernetCsmacd] 'Anonymized 124' [speed = ][status = up][id = 16777217][alias = ][type = propVirtual] '1/1/2' [speed = ][status = down][id = 2][alias = ][type = ethernetCsmacd] '1/1/3' [speed = 1000][status = up][id = 3][alias = ][type = ethernetCsmacd] '1/1/4' [speed = ][status = down][id = 4][alias = ][type = ethernetCsmacd] '1/1/5' [speed = ][status = down][id = 5][alias = ][type = ethernetCsmacd] '1/1/6' [speed = ][status = down][id = 6][alias = ][type = ethernetCsmacd] '1/1/7' [speed = ][status = down][id = 7][alias = ][type = ethernetCsmacd] 'Anonymized 066' [speed = 2000][status = up][id = 769][alias = ][type = ieee8023adLag] '1/1/8' [speed = ][status = down][id = 8][alias = ][type = ethernetCsmacd] '1/1/9' [speed = ][status = down][id = 9][alias = ][type = ethernetCsmacd]
            ...      2     --use-adminstatus='up' --speed=2000 --interface=1,1,10                         List interfaces: '1/1/1' [speed = 2000][status = up][id = 1][type = ethernetCsmacd] '1/1/10' [speed = 2000][status = down][id = 10][type = ethernetCsmacd]
            ...      3     --add-mac-address='' --interface=1,1,16                                        List interfaces: '1/1/1' [speed = 100][status = up][id = 1][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:32:34:38][type = ethernetCsmacd] '1/1/16' [speed = 1000][status = up][id = 16][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:30:36:38][type = ethernetCsmacd]
            ...      4     --display-transform-src='eth' --display-transform-dst='ens'                    List interfaces: '1/1/1' [speed = 100][status = up][id = 1][type = ethernetCsmacd] '1/1/10' [speed = ][status = down][id = 10][type = ethernetCsmacd] '1/1/11' [speed = ][status = down][id = 11][type = ethernetCsmacd] '1/1/12' [speed = ][status = down][id = 12][type = ethernetCsmacd] '1/1/13' [speed = ][status = down][id = 13][type = ethernetCsmacd] '1/1/14' [speed = ][status = down][id = 14][type = ethernetCsmacd] '1/1/15' [speed = 1000][status = up][id = 15][type = ethernetCsmacd] '1/1/16' [speed = 1000][status = up][id = 16][type = ethernetCsmacd] 'Anonymized 124' [speed = ][status = up][id = 16777217][type = propVirtual] '1/1/2' [speed = ][status = down][id = 2][type = ethernetCsmacd] '1/1/3' [speed = 1000][status = up][id = 3][type = ethernetCsmacd] '1/1/4' [speed = ][status = down][id = 4][type = ethernetCsmacd] '1/1/5' [speed = ][status = down][id = 5][type = ethernetCsmacd] '1/1/6' [speed = ][status = down][id = 6][type = ethernetCsmacd] '1/1/7' [speed = ][status = down][id = 7][type = ethernetCsmacd] 'Anonymized 066' [speed = 2000][status = up][id = 769][type = ieee8023adLag] '1/1/8' [speed = ][status = down][id = 8][type = ethernetCsmacd] '1/1/9' [speed = ][status = down][id = 9][type = ethernetCsmacd]
            ...      5     --filter-status='up|UP'                                                        List interfaces: '1/1/1' [speed = 100][status = up][id = 1][type = ethernetCsmacd] skipping interface '1/1/10': no matching filter status skipping interface '1/1/11': no matching filter status skipping interface '1/1/12': no matching filter status skipping interface '1/1/13': no matching filter status skipping interface '1/1/14': no matching filter status '1/1/15' [speed = 1000][status = up][id = 15][type = ethernetCsmacd] '1/1/16' [speed = 1000][status = up][id = 16][type = ethernetCsmacd] 'Anonymized 124' [speed = ][status = up][id = 16777217][type = propVirtual] skipping interface '1/1/2': no matching filter status '1/1/3' [speed = 1000][status = up][id = 3][type = ethernetCsmacd] skipping interface '1/1/4': no matching filter status skipping interface '1/1/5': no matching filter status skipping interface '1/1/6': no matching filter status skipping interface '1/1/7': no matching filter status 'Anonymized 066' [speed = 2000][status = up][id = 769][type = ieee8023adLag] skipping interface '1/1/8': no matching filter status skipping interface '1/1/9': no matching filter status
