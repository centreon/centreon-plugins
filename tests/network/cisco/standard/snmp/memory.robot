*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
memory ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --warning-usage                                                       OK: All memories are ok | 'used_Anonymized 021'=81605080B;;;0;366174644 'used_Anonymized 062'=40B;;;0;938040 'used_Anonymized 021'=40B;;;0;85960 'used_Anonymized 246'=12689640B;;;0;33554432 'used_Anonymized 135'=40B;;;0;1048576
            ...      2     --verbose                                                             OK: All memories are ok | 'used_Anonymized 021'=81605080B;;;0;366174644 'used_Anonymized 062'=40B;;;0;938040 'used_Anonymized 021'=40B;;;0;85960 'used_Anonymized 246'=12689640B;;;0;33554432 'used_Anonymized 135'=40B;;;0;1048576 Memory 'Anonymized 021' Usage Total: 349.21 MB Used: 77.82 MB (22.29%) Free: 271.39 MB (77.71%) Memory 'Anonymized 062' Usage Total: 916.05 KB Used: 40.00 B (0.00%) Free: 916.02 KB (100.00%) Memory 'Anonymized 021' Usage Total: 83.95 KB Used: 40.00 B (0.05%) Free: 83.91 KB (99.95%) Memory 'Anonymized 246' Usage Total: 32.00 MB Used: 12.10 MB (37.82%) Free: 19.90 MB (62.18%) Memory 'Anonymized 135' Usage Total: 1.00 MB Used: 40.00 B (0.00%) Free: 1023.96 KB (100.00%)
            ...      3     --critical-usage                                                      OK: All memories are ok | 'used_Anonymized 021'=81605080B;;;0;366174644 'used_Anonymized 062'=40B;;;0;938040 'used_Anonymized 021'=40B;;;0;85960 'used_Anonymized 246'=12689640B;;;0;33554432 'used_Anonymized 135'=40B;;;0;1048576
            ...      4     --filter-pool                                                         OK: All memories are ok | 'used_Anonymized 021'=81605080B;;;0;366174644 'used_Anonymized 062'=40B;;;0;938040 'used_Anonymized 021'=40B;;;0;85960 'used_Anonymized 246'=12689640B;;;0;33554432 'used_Anonymized 135'=40B;;;0;1048576
            ...      5     --check-order='enhanced_pool,pool,process,system_ext'                 OK: All memories are ok | 'used_Anonymized 021'=81605080B;;;0;366174644 'used_Anonymized 062'=40B;;;0;938040 'used_Anonymized 021'=40B;;;0;85960 'used_Anonymized 246'=12689640B;;;0;33554432 'used_Anonymized 135'=40B;;;0;1048576 
