*** Settings ***
Documentation       Check Huawei equipments in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::wlc::snmp::plugin


*** Test Cases ***
list-interfaces ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options} | grep -v 'skipping interface' | wc -l
 
    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc   extra_options                                               expected_result    --
            ...      1    ${EMPTY}                                                    185
            ...      2    --interface=12                                              2
            ...      3    --name --interface='Anonymized 25'                          8
            ...      4    --name --interface='Anonymized 23'                          10
            ...      5    --name --interface='Anonymized 25' --skip-speed0            6
            ...      6    --filter-status='down'                                      154
            ...      7    --filter-status='down' --skip-speed0                        153
