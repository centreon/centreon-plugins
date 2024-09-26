*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::windows::snmp::plugin

*** Test Cases ***
list-interfaces ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                               expected_result    --
            ...      1     --add-extra-oid=''                                                          List interfaces: ${SPACE}'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] ${SPACE}'eth0' [speed = ][status = up][id = 2][type = ethernetCsmacd] 
            ...      2     --add-extra-oid=''                                                          List interfaces: ${SPACE}'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] ${SPACE}'eth0' [speed = ][status = up][id = 2][type = ethernetCsmacd]
            ...      3     --add-mac-address=''                                                        List interfaces: ${SPACE}'lo' [speed = 10][status = up][id = 1][macaddress = ][type = softwareLoopback] ${SPACE}'eth0' [speed = ][status = up][id = 2][macaddress = 06:f3:50:2d:91:bb][type = ethernetCsmacd] 
            ...      4     --display-transform-src='eth'                                               List interfaces: ${SPACE}'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] ${SPACE}'0' [speed = ][status = up][id = 2][type = ethernetCsmacd]
            ...      5     --display-transform-dst='ens'                                               List interfaces: ${SPACE}'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] ${SPACE}'eth0' [speed = ][status = up][id = 2][type = ethernetCsmacd]
