*** Settings ***
Documentation       Check memory usage.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::standard::snmp::plugin


*** Test Cases ***
memory ${tc}
    [Tags]    network    Stormshield
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                             expected_result    --
            ...      7     --verbose                                                 OK: All memory usages are ok | 'used_1'=271388616B;;;0;1765801984 'used_2'=271382292B;;;0;1765801984 'used_3'=73684888B;;;0;1765801984 'used_4'=73684936B;;;0;1765801984 'used_5'=73708228B;;;0;1765801984 'used_6'=73690100B;;;0;1765801984 'used_7'=385327944B;;;0;1832910848 'used_8'=397826128B;;;0;1832910848 Memory '1' Total: 1.64 GB Used: 258.82 MB (15.37%) Free: 1.39 GB (84.63%) Memory '2' Total: 1.64 GB Used: 258.81 MB (15.37%) Free: 1.39 GB (84.63%) Memory '3' Total: 1.64 GB Used: 70.27 MB (4.17%) Free: 1.58 GB (95.83%) Memory '4' Total: 1.64 GB Used: 70.27 MB (4.17%) Free: 1.58 GB (95.83%) Memory '5' Total: 1.64 GB Used: 70.29 MB (4.17%) Free: 1.58 GB (95.83%) Memory '6' Total: 1.64 GB Used: 70.28 MB (4.17%) Free: 1.58 GB (95.83%) Memory '7' Total: 1.71 GB Used: 367.48 MB (21.02%) Free: 1.35 GB (78.98%) Memory '8' Total: 1.71 GB Used: 379.40 MB (21.70%) Free: 1.34 GB (78.30%)
            ...      2     --warning-usage=80                                        OK: All memory usages are ok | 'used_1'=271388616B;0:1412641587;;0;1765801984 'used_2'=271382292B;0:1412641587;;0;1765801984 'used_3'=73684888B;0:1412641587;;0;1765801984 'used_4'=73684936B;0:1412641587;;0;1765801984 'used_5'=73708228B;0:1412641587;;0;1765801984 'used_6'=73690100B;0:1412641587;;0;1765801984 'used_7'=385327944B;0:1466328678;;0;1832910848 'used_8'=397826128B;0:1466328678;;0;1832910848
            ...      3     --critical-usage=90                                       OK: All memory usages are ok | 'used_1'=271388616B;;0:1589221785;0;1765801984 'used_2'=271382292B;;0:1589221785;0;1765801984 'used_3'=73684888B;;0:1589221785;0;1765801984 'used_4'=73684936B;;0:1589221785;0;1765801984 'used_5'=73708228B;;0:1589221785;0;1765801984 'used_6'=73690100B;;0:1589221785;0;1765801984 'used_7'=385327944B;;0:1649619763;0;1832910848 'used_8'=397826128B;;0:1649619763;0;1832910848