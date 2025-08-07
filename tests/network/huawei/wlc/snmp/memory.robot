*** Settings ***
Documentation       Check memory usage.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::wlc::snmp::plugin


*** Test Cases ***
memory ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                             expected_result    --
            ...      1     ${EMPTY}                                                  OK: All memory usages are ok | 'used_1'=271388616B;;;0;1765801984 'used_2'=271382292B;;;0;1765801984 'used_3'=73684888B;;;0;1765801984 'used_4'=73684936B;;;0;1765801984 'used_5'=73708228B;;;0;1765801984 'used_6'=73690100B;;;0;1765801984 'used_7'=385327944B;;;0;1832910848 'used_8'=397826128B;;;0;1832910848
            ...      2     --warning-usage=10                                        WARNING: Memory '1' Total: 1.64 GB Used: 258.82 MB (15.37%) Free: 1.39 GB (84.63%) - Memory '2' Total: 1.64 GB Used: 258.81 MB (15.37%) Free: 1.39 GB (84.63%) - Memory '7' Total: 1.71 GB Used: 367.48 MB (21.02%) Free: 1.35 GB (78.98%) - Memory '8' Total: 1.71 GB Used: 379.40 MB (21.70%) Free: 1.34 GB (78.30%) | 'used_1'=271388616B;0:176580198;;0;1765801984 'used_2'=271382292B;0:176580198;;0;1765801984 'used_3'=73684888B;0:176580198;;0;1765801984 'used_4'=73684936B;0:176580198;;0;1765801984 'used_5'=73708228B;0:176580198;;0;1765801984 'used_6'=73690100B;0:176580198;;0;1765801984 'used_7'=385327944B;0:183291084;;0;1832910848 'used_8'=397826128B;0:183291084;;0;1832910848
            ...      3     --critical-usage=10                                       CRITICAL: Memory '1' Total: 1.64 GB Used: 258.82 MB (15.37%) Free: 1.39 GB (84.63%) - Memory '2' Total: 1.64 GB Used: 258.81 MB (15.37%) Free: 1.39 GB (84.63%) - Memory '7' Total: 1.71 GB Used: 367.48 MB (21.02%) Free: 1.35 GB (78.98%) - Memory '8' Total: 1.71 GB Used: 379.40 MB (21.70%) Free: 1.34 GB (78.30%) | 'used_1'=271388616B;;0:176580198;0;1765801984 'used_2'=271382292B;;0:176580198;0;1765801984 'used_3'=73684888B;;0:176580198;0;1765801984 'used_4'=73684936B;;0:176580198;0;1765801984 'used_5'=73708228B;;0:176580198;0;1765801984 'used_6'=73690100B;;0:176580198;0;1765801984 'used_7'=385327944B;;0:183291084;0;1832910848 'used_8'=397826128B;;0:183291084;0;1832910848

