*** Settings ***
Documentation       Check Huawei equipments in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::wlc::snmp::plugin


*** Test Cases ***
list-radios ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-radios
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options} | wc -l

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                            expected_result    --
            ...      1     --filter-name='Anonymized 0'             100
            ...      2     --filter-name='Anonymized 1'             100
            ...      3     --filter-name='Anonymized 2'             56
            ...      4     ${EMPTY}                                 254
