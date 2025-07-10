*** Settings ***
Documentation       Forcepoint SD-WAN Mode List Interfaces

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin


*** Test Cases ***
list-interfaces ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=40000
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint-listinterfaces
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                               expected_result    --
            ...      1     --add-extra-oid=''                                                          List interfaces: 'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] 'stu6' [speed = 1000][status = up][id = 10][type = ethernetCsmacd] 'vwx7' [speed = 1000][status = up][id = 11][type = ethernetCsmacd] 'Anonymized 073' [speed = ][status = up][id = 12][type = other] 'Anonymized 071' [speed = 1000][status = up][id = 13][type = ethernetCsmacd] 'Anonymized 073' [speed = 1000][status = up][id = 14][type = ethernetCsmacd] 'Anonymized 232' [speed = 1000][status = up][id = 15][type = ethernetCsmacd] 'Anonymized 191' [speed = ][status = up][id = 16][type = ethernetCsmacd] 'Anonymized 184' [speed = ][status = down][id = 3][type = tunnel] 'abc0' [speed = 1000][status = up][id = 4][type = ethernetCsmacd] 'def1' [speed = 1000][status = up][id = 5][type = ethernetCsmacd] 'ghi2' [speed = 1000][status = up][id = 6][type = ethernetCsmacd] 'jkl3' [speed = ][status = down][id = 7][type = ethernetCsmacd] 'mno4' [speed = ][status = down][id = 8][type = ethernetCsmacd] 'prq5' [speed = 1000][status = up][id = 9][type = ethernetCsmacd]
            ...      2     --add-mac-address                                                           List interfaces: 'lo' [speed = 10][status = up][id = 1][macaddress = ][type = softwareLoopback] 'stu6' [speed = 1000][status = up][id = 10][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:30:38:34][type = ethernetCsmacd] 'vwx7' [speed = 1000][status = up][id = 11][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:31:38:34][type = ethernetCsmacd] 'Anonymized 073' [speed = ][status = up][id = 12][macaddress = ][type = other] 'Anonymized 071' [speed = 1000][status = up][id = 13][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:31:31:39][type = ethernetCsmacd] 'Anonymized 073' [speed = 1000][status = up][id = 14][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:30:31:30][type = ethernetCsmacd] 'Anonymized 232' [speed = 1000][status = up][id = 15][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:31:37:32][type = ethernetCsmacd] 'Anonymized 191' [speed = ][status = up][id = 16][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:30:36:38][type = ethernetCsmacd] 'Anonymized 184' [speed = ][status = down][id = 3][macaddress = ][type = tunnel] 'abc0' [speed = 1000][status = up][id = 4][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:30:30:33][type = ethernetCsmacd] 'def1' [speed = 1000][status = up][id = 5][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:31:33:32][type = ethernetCsmacd] 'ghi2' [speed = 1000][status = up][id = 6][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:30:32:36][type = ethernetCsmacd] 'jkl3' [speed = ][status = down][id = 7][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:31:36:37][type = ethernetCsmacd] 'mno4' [speed = ][status = down][id = 8][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:31:39:38][type = ethernetCsmacd] 'prq5' [speed = 1000][status = up][id = 9][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:30:38:35][type = ethernetCsmacd]
            ...      3     --display-transform-src='Anonymized' --display-transform-dst='Knowned'      List interfaces: 'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] 'stu6' [speed = 1000][status = up][id = 10][type = ethernetCsmacd] 'vwx7' [speed = 1000][status = up][id = 11][type = ethernetCsmacd] 'Knowned 073' [speed = ][status = up][id = 12][type = other] 'Knowned 071' [speed = 1000][status = up][id = 13][type = ethernetCsmacd] 'Knowned 073' [speed = 1000][status = up][id = 14][type = ethernetCsmacd] 'Knowned 232' [speed = 1000][status = up][id = 15][type = ethernetCsmacd] 'Knowned 191' [speed = ][status = up][id = 16][type = ethernetCsmacd] 'Knowned 184' [speed = ][status = down][id = 3][type = tunnel] 'abc0' [speed = 1000][status = up][id = 4][type = ethernetCsmacd] 'def1' [speed = 1000][status = up][id = 5][type = ethernetCsmacd] 'ghi2' [speed = 1000][status = up][id = 6][type = ethernetCsmacd] 'jkl3' [speed = ][status = down][id = 7][type = ethernetCsmacd] 'mno4' [speed = ][status = down][id = 8][type = ethernetCsmacd] 'prq5' [speed = 1000][status = up][id = 9][type = ethernetCsmacd]
