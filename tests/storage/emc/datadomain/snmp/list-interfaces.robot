*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
list-interfaces ${tc}
    [Tags]    snmp    storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/slim-datadomain
    ...    --snmp-timeout=1
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Contain
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

    Examples:        tc    extra_options                                                     expected_result    --
            ...      1     --verbose                                                         List interfaces: 'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] 'Anonymized 012' [speed = 10000][status = up][id = 10][type = ethernetCsmacd] 'Anonymized 118' [speed = ][status = down][id = 11][type = ethernetCsmacd] 'Anonymized 073' [speed = ][status = down][id = 12][type = ethernetCsmacd] 'Anonymized 071' [speed = 10000][status = up][id = 13][type = ethernetCsmacd] 'Anonymized 073' [speed = 10000][status = up][id = 14][type = ethernetCsmacd] 'Anonymized 232' [speed = 10000][status = up][id = 15][type = ethernetCsmacd] 'Anonymized 191' [speed = 10000][status = up][id = 16][type = ethernetCsmacd] 'Anonymized 242' [speed = ][status = up][id = 17][type = ethernetCsmacd] 'Anonymized 175' [speed = 20000][status = up][id = 18][type = ethernetCsmacd] 'Anonymized 128' [speed = 60000][status = up][id = 19][type = ethernetCsmacd] 'Anonymized 037' [speed = ][status = down][id = 2][type = ethernetCsmacd] 'Anonymized 184' [speed = ][status = down][id = 3][type = ethernetCsmacd] 'Anonymized 252' [speed = ][status = down][id = 5][type = ethernetCsmacd] 'Anonymized 012' [speed = ][status = down][id = 6][type = ethernetCsmacd] 'Anonymized 232' [speed = 10000][status = up][id = 7][type = ethernetCsmacd] 'Anonymized 072' [speed = 10000][status = up][id = 8][type = ethernetCsmacd] 'Anonymized 037' [speed = 10000][status = up][id = 9][type = ethernetCsmacd]
            ...      2     --add-extra-oid='alias,.1.3.6.1.2.1.31.1.1.1.18'                  List interfaces: 'lo' [speed = 10][status = up][id = 1][alias = ][type = softwareLoopback] 'Anonymized 012' [speed = 10000][status = up][id = 10][alias = ][type = ethernetCsmacd] 'Anonymized 118' [speed = ][status = down][id = 11][alias = ][type = ethernetCsmacd] 'Anonymized 073' [speed = ][status = down][id = 12][alias = ][type = ethernetCsmacd] 'Anonymized 071' [speed = 10000][status = up][id = 13][alias = ][type = ethernetCsmacd] 'Anonymized 073' [speed = 10000][status = up][id = 14][alias = ][type = ethernetCsmacd]
            ...      3     --add-mac-address                                                 List interfaces: 'lo' [speed = 10][status = up][id = 1][macaddress = ][type = softwareLoopback] 'Anonymized 012' [speed = 10000][status = up][id = 10][macaddress = f4:c7:aa:55:8a:d5][type = ethernetCsmacd] 'Anonymized 118' [speed = ][status = down][id = 11][macaddress = f4:c7:aa:4e:46:02][type = ethernetCsmacd] 'Anonymized 073' [speed = ][status = down][id = 12][macaddress = f4:c7:aa:4e:46:03][type = ethernetCsmacd] 'Anonymized 071' [speed = 10000][status = up][id = 13][macaddress = f4:c7:aa:55:8a:d4][type = ethernetCsmacd] 'Anonymized 073' [speed = 10000][status = up][id = 14][macaddress = f4:c7:aa:55:8a:d5][type = ethernetCsmacd] 'Anonymized 232' [speed = 10000][status = up][id = 15]
            ...      4     --display-transform-src='eth' --display-transform-dst='ens'       List interfaces: 'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] 'Anonymized 012' [speed = 10000][status = up][id = 10][type = ethernetCsmacd] 'Anonymized 118' [speed = ][status = down][id = 11][type = ethernetCsmacd] 'Anonymized 073' [speed = ][status = down][id = 12][type = ethernetCsmacd] 'Anonymized 071' [speed = 10000][status = up][id = 13][type = ethernetCsmacd] 'Anonymized 073' [speed = 10000][status = up][id = 14][type = ethernetCsmacd] 'Anonymized 232' [speed = 10000][status = up][id = 15][type = ethernetCsmacd] 'Anonymized 191' [speed = 10000][status = up][id = 16][type = ethernetCsmacd] 'Anonymized 242' [speed = ][status = up][id = 17][type = ethernetCsmacd] 'Anonymized 175' [speed = 20000][status = up][id = 18][type = ethernetCsmacd] 'Anonymized 128' [speed = 60000][status = up][id = 19][type = ethernetCsmacd] 'Anonymized 037' [speed = ][status = down][id = 2][type = ethernetCsmacd] 'Anonymized 184' [speed = ][status = down][id = 3][type = ethernetCsmacd] 'Anonymized 252' [speed = ][status = down][id = 5][type = ethernetCsmacd] 'Anonymized 012' [speed = ][status = down][id = 6][type = ethernetCsmacd] 'Anonymized 232' [speed = 10000][status = up][id = 7][type = ethernetCsmacd] 'Anonymized 072' [speed = 10000][status = up][id = 8][type = ethernetCsmacd] 'Anonymized 037' [speed = 10000][status = up][id = 9][type = ethernetCsmacd]
            ...      5     --oid-display='ifName'                                            List interfaces: 'lo' [speed = 10][status = up][id = 1][type = softwareLoopback] 'Anonymized 012' [speed = 10000][status = up][id = 10][type = ethernetCsmacd] 'Anonymized 118' [speed = ][status = down][id = 11][type = ethernetCsmacd] 'Anonymized 073' [speed = ][status = down][id = 12][type = ethernetCsmacd] 'Anonymized 071' [speed = 10000][status = up][id = 13][type = ethernetCsmacd] 'Anonymized 073' [speed = 10000][status = up][id = 14][type = ethernetCsmacd] 'Anonymized 232' [speed = 10000][status = up][id = 15][type = ethernetCsmacd] 'Anonymized 191' [speed = 10000][status = up][id = 16][type = ethernetCsmacd] 'Anonymized 242' [speed = ][status = up][id = 17][type = ethernetCsmacd] 'Anonymized 175' [speed = 20000][status = up][id = 18][type = ethernetCsmacd] 'Anonymized 128' [speed = 60000][status = up][id = 19][type = ethernetCsmacd] 'Anonymized 037' [speed = ][status = down][id = 2][type = ethernetCsmacd] 'Anonymized 184' [speed = ][status = down][id = 3][type = ethernetCsmacd] 'Anonymized 252' [speed = ][status = down][id = 5][type = ethernetCsmacd] 'Anonymized 012' [speed = ][status = down][id = 6][type = ethernetCsmacd] 'Anonymized 232' [speed = 10000][status = up][id = 7][type = ethernetCsmacd] 'Anonymized 072' [speed = 10000][status = up][id = 8][type = ethernetCsmacd] 'Anonymized 037' [speed = 10000][status = up][id = 9][type = ethernetCsmacd]
