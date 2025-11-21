*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
list-interfaces ${tc}
    [Tags]    network    list-interfaces    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Contain
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     ${EMPTY}                                                              List interfaces: 'Anonymized 250' [speed = 1000][status = down][id = 1][type = propVirtual] 'Anonymized 072' [speed = 1000][status = up][id = 10101][type = ethernetCsmacd] 'Anonymized 064' [speed = 1000][status = up][id = 10102][type = ethernetCsmacd] 'Anonymized 254' [speed = 1000][status = up][id = 10103][type = ethernetCsmacd] 'Anonymized 243' [speed = 1000][status = up][id = 10104][type = ethernetCsmacd] 'Anonymized 071' [speed = 10][status = down][id = 10105][type = ethernetCsmacd] 'Anonymized 023' [speed = 10][status = down][id = 10106][type = ethernetCsmacd]
            ...      2     --add-extra-oid='alias,.1.3.6.1.2.1.31.1.1.1.18'                      'Anonymized 250' [speed = 1000][status = down][id = 1][alias = ][type = propVirtual]
            ...      3     --display-transform-src='eth' --display-transform-dst='ens'           'Anonymized 250' [speed = 1000][status = down][id = 1][type = propVirtual]
            ...      4     --add-mac-address                                                     'Anonymized 250' [speed = 1000][status = down][id = 1][macaddress = 41:6e:6f:6e:79:6d:69:7a:65:64:20:32:34:38][type = propVirtual]
