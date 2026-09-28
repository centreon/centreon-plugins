*** Settings ***
Documentation       network::huawei::standard::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::huawei::standard::snmp::plugin
...         --mode=list-gpon-ont
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/huawei/standard/snmp/huawei-gpon


*** Test Cases ***
List-gpon-ont ${tc}
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
    ...    List ONT: [Name = DSLAM ANO 3] [Serial = ANON00000003] [Serial Hex = 414E4F4E00000003] [State = active] [Name = xDSL ANO 1] [Serial = ANON00000001] [Serial Hex = 414E4F4E00000001] [State = active] [Name = xDSL ANO 2] [Serial = ANON00000002] [Serial Hex = 414E4F4E00000002] [State = notReady]
    ...    2
    ...    --include-name='xDSL ANO 1'
    ...    List ONT: [Name = xDSL ANO 1] [Serial = ANON00000001] [Serial Hex = 414E4F4E00000001] [State = active]
    ...    3
    ...    --exclude-name='xDSL ANO'
    ...    List ONT: [Name = DSLAM ANO 3] [Serial = ANON00000003] [Serial Hex = 414E4F4E00000003] [State = active]
    ...    4
    ...    --include-serial='ANON00000003'
    ...    List ONT: [Name = DSLAM ANO 3] [Serial = ANON00000003] [Serial Hex = 414E4F4E00000003] [State = active]
    ...    5
    ...    --exclude-serial='ANON00000003'
    ...    List ONT: [Name = xDSL ANO 1] [Serial = ANON00000001] [Serial Hex = 414E4F4E00000001] [State = active] [Name = xDSL ANO 2] [Serial = ANON00000002] [Serial Hex = 414E4F4E00000002] [State = notReady]
    ...    6
    ...    --include-status='notReady'
    ...    List ONT: [Name = xDSL ANO 2] [Serial = ANON00000002] [Serial Hex = 414E4F4E00000002] [State = notReady]
    ...    7
    ...    --exclude-status='active' --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label name="xDSL ANO 2" serial="ANON00000002" serial_hex="414E4F4E00000002" state="notReady"/> </data>
    ...    8
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>name</element> <element>serial</element> <element>serial_hex</element> <element>state</element> </data>
