*** Settings ***
Documentation       Check Huawei equipments in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::wlc::snmp::plugin


*** Test Cases ***
list-radios ${tc}
    [Tags]    network    Stormshield
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-radios
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Verify Command Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                             expected_result    --
            ...      7     --verbose                                                 List aps [oid_path: 128.105.51.109.163.224.1] [name: Anonymized 204] [frequence_type: 2] [run_state: up] [description: Anonymized 192] [ap_group: Anonymized 117] [oid_path: 156.29.54.248.206.128.1] [name: Anonymized 176] [frequence_type: 2] [run_state: up] [description: Anonymized 011] [ap_group: Anonymized 055] [oid_path: 156.29.54.248.207.96.1] [name: Anonymized 003] [frequence_type: 2] [run_state: up] [description: Anonymized 055] [ap_group: Anonymized 220] [oid_path: 204.187.254.13.97.224.0] [name: Anonymized 156] [frequence_type: 1] [run_state: up] [description: Anonymized 154] [ap_group: Anonymized 126] [oid_path: 204.187.254.13.97.96.0] [name: Anonymized 203] [frequence_type: 1] [run_state: up] [description: Anonymized 025] [ap_group: Anonymized 024] [oid_path: 204.187.254.13.99.224.1] [name: Anonymized 125] [frequence_type: 2] [run_state: up] [description: Anonymized 064] [ap_group: Anonymized 176]
            ...      2     --filter-name                                             List aps [oid_path: 128.105.51.109.163.224.1] [name: Anonymized 204] [frequence_type: 2] [run_state: up] [description: Anonymized 192] [ap_group: Anonymized 117] [oid_path: 156.29.54.248.206.128.1] [name: Anonymized 176] [frequence_type: 2] [run_state: up] [description: Anonymized 011] [ap_group: Anonymized 055] [oid_path: 156.29.54.248.207.96.1] [name: Anonymized 003] [frequence_type: 2] [run_state: up] [description: Anonymized 055] [ap_group: Anonymized 220] [oid_path: 204.187.254.13.97.224.0] [name: Anonymized 156] [frequence_type: 1] [run_state: up] [description: Anonymized 154] [ap_group: Anonymized 126] [oid_path: 204.187.254.13.97.96.0] [name: Anonymized 203] [frequence_type: 1] [run_state: up] [description: Anonymized 025] [ap_group: Anonymized 024] [oid_path: 204.187.254.13.99.224.1] [name: Anonymized 125] [frequence_type: 2] [run_state: up] [description: Anonymized 064] [ap_group: Anonymized 176]
            ...      3     --filter-group                                            List aps [oid_path: 128.105.51.109.163.224.1] [name: Anonymized 204] [frequence_type: 2] [run_state: up] [description: Anonymized 192] [ap_group: Anonymized 117] [oid_path: 156.29.54.248.206.128.1] [name: Anonymized 176] [frequence_type: 2] [run_state: up] [description: Anonymized 011] [ap_group: Anonymized 055] [oid_path: 156.29.54.248.207.96.1] [name: Anonymized 003] [frequence_type: 2] [run_state: up] [description: Anonymized 055] [ap_group: Anonymized 220] [oid_path: 204.187.254.13.97.224.0] [name: Anonymized 156] [frequence_type: 1] [run_state: up] [description: Anonymized 154] [ap_group: Anonymized 126] [oid_path: 204.187.254.13.97.96.0] [name: Anonymized 203] [frequence_type: 1] [run_state: up] [description: Anonymized 025] [ap_group: Anonymized 024] [oid_path: 204.187.254.13.99.224.1] [name: Anonymized 125] [frequence_type: 2] [run_state: up] [description: Anonymized 064] [ap_group: Anonymized 176]