*** Settings ***
Documentation       Check CPU usages.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::huawei::wlc::snmp::plugin


*** Test Cases ***
cpu ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/huawei/wlc/snmp/slim_huawei_wlc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                            expected_result    --
            ...      1     --verbose                                                OK: All CPU usages are ok | 'cpu_1'=14.00%;;;0;100 'cpu_2'=16.00%;;;0;100 'cpu_3'=14.00%;;;0;100 'cpu_4'=12.00%;;;0;100 'cpu_5'=13.00%;;;0;100 'cpu_6'=13.00%;;;0;100 'cpu_7'=21.00%;;;0;100 'cpu_8'=10.00%;;;0;100${\n}CPU '1' Usage : 14.00 %${\n}CPU '2' Usage : 16.00 %${\n}CPU '3' Usage : 14.00 %${\n}CPU '4' Usage : 12.00 %${\n}CPU '5' Usage : 13.00 %${\n}CPU '6' Usage : 13.00 %${\n}CPU '7' Usage : 21.00 %${\n}CPU '8' Usage : 10.00 %
            ...      2     --warning-usage="-5:5"                                   WARNING: CPU '1' Usage : 14.00 % - CPU '2' Usage : 16.00 % - CPU '3' Usage : 14.00 % - CPU '4' Usage : 12.00 % - CPU '5' Usage : 13.00 % - CPU '6' Usage : 13.00 % - CPU '7' Usage : 21.00 % - CPU '8' Usage : 10.00 % | 'cpu_1'=14.00%;-5:5;;0;100 'cpu_2'=16.00%;-5:5;;0;100 'cpu_3'=14.00%;-5:5;;0;100 'cpu_4'=12.00%;-5:5;;0;100 'cpu_5'=13.00%;-5:5;;0;100 'cpu_6'=13.00%;-5:5;;0;100 'cpu_7'=21.00%;-5:5;;0;100 'cpu_8'=10.00%;-5:5;;0;100
            ...      3     --critical-usage="-10:10"                                CRITICAL: CPU '1' Usage : 14.00 % - CPU '2' Usage : 16.00 % - CPU '3' Usage : 14.00 % - CPU '4' Usage : 12.00 % - CPU '5' Usage : 13.00 % - CPU '6' Usage : 13.00 % - CPU '7' Usage : 21.00 % | 'cpu_1'=14.00%;;-10:10;0;100 'cpu_2'=16.00%;;-10:10;0;100 'cpu_3'=14.00%;;-10:10;0;100 'cpu_4'=12.00%;;-10:10;0;100 'cpu_5'=13.00%;;-10:10;0;100 'cpu_6'=13.00%;;-10:10;0;100 'cpu_7'=21.00%;;-10:10;0;100 'cpu_8'=10.00%;;-10:10;0;100
