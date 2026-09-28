*** Settings ***
Documentation       network::huawei::standard::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::huawei::standard::snmp::plugin
...         --mode=gpon-ont-ethernet-port
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/huawei/standard/snmp/huawei-gpon


*** Test Cases ***
Gpon-ont-ethernet-port ${tc}
    [Tags]    network    huawei    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    CRITICAL: ONT 'xDSL ANO 2' - ANON00000002(414E4F4E00000002) ethernet port 1 (autospeed100M) status : linkdown
    ...    2
    ...    --include-serial=ANON00000001
    ...    OK: ONT 'xDSL ANO 1' - ANON00000001(414E4F4E00000001) ethernet port 1 (autospeed10M) status : linkup
    ...    3
    ...    --exclude-serial=ANON00000002
    ...    OK: All ONT ethernet port are ok
    ...    4
    ...    --warning-status='\\\%{online_state} =~ /linkdown/' --critical-status=''
    ...    WARNING: ONT 'xDSL ANO 2' - ANON00000002(414E4F4E00000002) ethernet port 1 (autospeed100M) status : linkdown
    ...    5
    ...    --critical-status='\\\%{online_state} =~ /linkup/'
    ...    CRITICAL: ONT 'xDSL ANO 1' - ANON00000001(414E4F4E00000001) ethernet port 1 (autospeed10M) status : linkup - ONT 'DSLAM ANO 3' - ANON00000003(414E4F4E00000003) ethernet port 1 (autospeed1000M) status : linkup
