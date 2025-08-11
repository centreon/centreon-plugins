*** Settings ***
Documentation       List wireless name.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::wlc::snmp::plugin


*** Test Cases ***
list-aps ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-aps
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                             expected_result    --
            ...      1     --verbose --filter-name='Anonymized 058'                                  List aps [oid_path: 100.19.171.37.61.112] [name: Anonymized 058] [serial: Anonymized 021] [address: 192.168.42.33] [hardware: Anonymized 104] [software: Anonymized 014] [run_time: 1w 4d 3h 1m 45s] [ap_group: Anonymized 214] [oid_path: 128.105.51.109.163.32] [name: Anonymized 058] [serial: Anonymized 025] [address: 192.168.42.225] [hardware: Anonymized 167] [software: Anonymized 034] [run_time: 11M 1w 1d 6h 12m 17s] [ap_group: Anonymized 040] [oid_path: 52.30.107.186.232.64] [name: Anonymized 058] [serial: Anonymized 073] [address: 192.168.42.66] [hardware: Anonymized 033] [software: Anonymized 168] [run_time: 11M 1w 1d 6h 15m 30s] [ap_group: Anonymized 124]
            ...      2     --filter-name='Anonymized 058'                                            List aps [oid_path: 100.19.171.37.61.112] [name: Anonymized 058] [serial: Anonymized 021] [address: 192.168.42.33] [hardware: Anonymized 104] [software: Anonymized 014] [run_time: 1w 4d 3h 1m 45s] [ap_group: Anonymized 214] [oid_path: 128.105.51.109.163.32] [name: Anonymized 058] [serial: Anonymized 025] [address: 192.168.42.225] [hardware: Anonymized 167] [software: Anonymized 034] [run_time: 11M 1w 1d 6h 12m 17s] [ap_group: Anonymized 040] [oid_path: 52.30.107.186.232.64] [name: Anonymized 058] [serial: Anonymized 073] [address: 192.168.42.66] [hardware: Anonymized 033] [software: Anonymized 168] [run_time: 11M 1w 1d 6h 15m 30s] [ap_group: Anonymized 124]                                                
            ...      3     --filter-address='192.168.42.230'                                         List aps [oid_path: 100.19.171.37.62.176] [name: Anonymized 140] [serial: Anonymized 036] [address: 192.168.42.230] [hardware: Anonymized 194] [software: Anonymized 196] [run_time: 1w 1d 2h 39m 24s] [ap_group: Anonymized 244] [oid_path: 244.29.107.141.73.192] [name: Anonymized 119] [serial: Anonymized 056] [address: 192.168.42.230] [hardware: Anonymized 070] [software: Anonymized 171] [run_time: 11M 1w 1d 6h 13m 59s] [ap_group: Anonymized 002] [oid_path: 244.29.107.141.80.64] [name: Anonymized 108] [serial: Anonymized 089] [address: 192.168.42.230] [hardware: Anonymized 062] [software: Anonymized 091] [run_time: 6d 6h 56m 42s] [ap_group: Anonymized 253]
            ...      4     --filter-group --filter-name='Anonymized 058'                             List aps [oid_path: 100.19.171.37.61.112] [name: Anonymized 058] [serial: Anonymized 021] [address: 192.168.42.33] [hardware: Anonymized 104] [software: Anonymized 014] [run_time: 1w 4d 3h 1m 45s] [ap_group: Anonymized 214] [oid_path: 128.105.51.109.163.32] [name: Anonymized 058] [serial: Anonymized 025] [address: 192.168.42.225] [hardware: Anonymized 167] [software: Anonymized 034] [run_time: 11M 1w 1d 6h 12m 17s] [ap_group: Anonymized 040] [oid_path: 52.30.107.186.232.64] [name: Anonymized 058] [serial: Anonymized 073] [address: 192.168.42.66] [hardware: Anonymized 033] [software: Anonymized 168] [run_time: 11M 1w 1d 6h 15m 30s] [ap_group: Anonymized 124]
