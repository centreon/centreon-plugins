*** Settings ***
Documentation       Check list-interfaces table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
list-interfaces ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                               expected_result    --
            ...      1     --add-extra-oid='alias,.1.3.6.1.2.1.31.1.1.1.18'                            List interfaces: ${SPACE}'lo' [speed = 10][status = up][id = 1][alias = ][type = softwareLoopback] 'eth0' [speed = 1000][status = up][id = 2][alias = ][type = ethernetCsmacd] ${SPACE} 'eth1' [speed = 1000][status = up][id = 3][alias = ][type = ethernetCsmacd]
            ...      2     --add-extra-oid=''                                                          List interfaces: ${SPACE}'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] ${SPACE} 'eth0' [speed = 1000][status = up][id = 2][type = ethernetCsmacd] ${SPACE}'eth1' [speed = 1000][status = up][id = 3][type = ethernetCsmacd]
            ...      3     --add-mac-address=''                                                        List interfaces: ${SPACE}'lo' [speed = 10][status = up][id = 1][macaddress = ][type = softwareLoopback] ${SPACE} 'eth0' [speed = 1000][status = up][id = 2][macaddress = 08:00:27:8d:c0:4d][type = ethernetCsmacd] ${SPACE} 'eth1' [speed = 1000][status = up][id = 3][macaddress = 08:00:27:af:8a:b1][type = ethernetCsmacd] 
            ...      4     --display-transform-src='eth'                                               List interfaces:${SPACE} 'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] ${SPACE} '0' [speed = 1000][status = up][id = 2][type = ethernetCsmacd] ${SPACE} '1' [speed = 1000][status = up][id = 3][type = ethernetCsmacd]
            ...      5     --display-transform-dst='ens'                                               List interfaces:${SPACE} 'lo' [speed = 10][status = up][id = 1][type = softwareLoopback]${SPACE} 'eth0' [speed = 1000][status = up][id = 2][type = ethernetCsmacd] ${SPACE} 'eth1' [speed = 1000][status = up][id = 3][type = ethernetCsmacd]