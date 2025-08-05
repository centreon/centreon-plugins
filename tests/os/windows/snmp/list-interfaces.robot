*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::windows::snmp::plugin

*** Test Cases ***
list-interfaces ${tc}
    [Tags]    os    Windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/list-interfaces
    ...    ${extra_options}
 
    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                               expected_result    --
            ...      1     --add-extra-oid='alias,.1.3.6.1.2.1.31.1.1.1.18'                            List interfaces:${SPACE}'loopback_0' [speed = 1073][status = up][id = 1][alias = Loopback Pseudo-Interface 1][type = softwareLoopback]
            ...      2     --add-extra-oid='vlan,.1.3.6.1.2.1.31.19,\\\%{instance}\..*'                List interfaces:${SPACE}'loopback_0' [speed = 1073][status = up][id = 1][type = softwareLoopback]${SPACE}'ethernet_32768' [speed = ][status = notPresent][id = 10][type = ethernetCsmacd]
            ...      3     --add-mac-address=''                                                        List interfaces:${SPACE}'loopback_0' [speed = 1073][status = up][id = 1][macaddress = ][type = softwareLoopback]${SPACE}'ethernet_32768' [speed = ][status = notPresent][id = 10][macaddress = ][type = ethernetCsmacd]${SPACE}'tunnel_32512' [speed = ][status = notPresent][id = 11][macaddress = ][type = tunnel]${SPACE}'ethernet_32772' [speed = ][status = up][id = 12][macaddress = ][type = ethernetCsmacd]${SPACE}'ethernet_32769' [speed = 1000][status = up][id = 13][macaddress = 00:50:56:ab:a2:f7][type = ethernetCsmacd]${SPACE}'ethernet_32770' [speed = ][status = up][id = 14][macaddress = ][type = ethernetCsmacd]
            ...      4     --display-transform-src='eth' --display-transform-dst='ens'                 List interfaces:${SPACE}'loopback_0' [speed = 1073][status = up][id = 1][type = softwareLoopback]${SPACE}'ensernet_32768' [speed = ][status = notPresent][id = 10][type = ethernetCsmacd]${SPACE}'tunnel_32512' [speed = ][status = notPresent][id = 11][type = tunnel]${SPACE}'ensernet_32772' [speed = ][status = up][id = 12][type = ethernetCsmacd]${SPACE}'ensernet_32769' [speed = 1000][status = up][id = 13][type = ethernetCsmacd]${SPACE}'ensernet_32770' [speed = ][status = up][id = 14][type = ethernetCsmacd]${SPACE}'tunnel_32770' [speed = ][status = down][id = 15][type = tunnel]${SPACE}'ensernet_0' [speed = 1000][status = up][id = 16][type = ethernetCsmacd]${SPACE}'ensernet_1' [speed = 1000][status = up][id = 17][type = ethernetCsmacd]${SPACE}'ensernet_2' [speed = 1000][status = up][id = 18][type = ethernetCsmacd]${SPACE}'ensernet_3' [speed = ][status = up][id = 19][type = ethernetCsmacd]${SPACE}'tunnel_32514' [speed = ][status = notPresent][id = 2][type = tunnel]${SPACE}'ensernet_4' [speed = ][status = up][id = 20][type = ethernetCsmacd]${SPACE}'ensernet_5' [speed = ][status = up][id = 21][type = ethernetCsmacd]${SPACE}'ensernet_6' [speed = ][status = up][id = 22][type = ethernetCsmacd]${SPACE}'ensernet_7' [speed = ][status = up][id = 23][type = ethernetCsmacd]${SPACE}'ensernet_8' [speed = ][status = up][id = 24][type = ethernetCsmacd]${SPACE}'tunnel_32769' [speed = ][status = down][id = 3][type = tunnel]${SPACE}'tunnel_32768' [speed = ][status = down][id = 4][type = tunnel]${SPACE}'tunnel_32513' [speed = ][status = notPresent][id = 5][type = tunnel]${SPACE}'tunnel_32772' [speed = ][status = down][id = 6][type = tunnel]${SPACE}'ppp_32768' [speed = ][status = down][id = 7][type = ppp]${SPACE}'tunnel_32771' [speed = ][status = down][id = 8][type = tunnel]${SPACE}'ensernet_32771' [speed = ][status = up][id = 9][type = ethernetCsmacd]
