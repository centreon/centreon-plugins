*** Settings ***
Documentation       Cisco standard SNMP plugin, list-port-security mode (CISCO-PORT-SECURITY-MIB).

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
list-port-security ${tc}
    [Tags]    network    cisco    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-port-security
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco-catalyst-port-security
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                       expected_result    --
            ...      1     --include-interface='^Gi1/0/[2-4]$'                 List port security interfaces: [name: Gi1/0/2][description: GigabitEthernet1/0/2][alias: Access-A][index: 10][port_security: enabled][status: secureup][violation_action: dropNotify][admin_status: up][oper_status: up] [name: Gi1/0/3][description: GigabitEthernet1/0/3][alias: Access-A][index: 11][port_security: disabled][status: securedown][violation_action: shutdown][admin_status: down][oper_status: down] [name: Gi1/0/4][description: GigabitEthernet1/0/4][alias: Access-A][index: 12][port_security: enabled][status: secureup][violation_action: dropNotify][admin_status: up][oper_status: up]
            ...      2     --exclude-interface='^Gi1/0/'                       List port security interfaces: [name: Gi1/1/1][description: GigabitEthernet1/1/1][alias: Uplink-Spare][index: 33][port_security: disabled][status: securedown][violation_action: shutdown][admin_status: up][oper_status: down] [name: Gi1/1/2][description: GigabitEthernet1/1/2][alias: Uplink-Spare][index: 34][port_security: disabled][status: securedown][violation_action: shutdown][admin_status: up][oper_status: down] [name: Gi1/1/3][description: GigabitEthernet1/1/3][alias: Uplink-Core][index: 35][port_security: disabled][status: securedown][violation_action: shutdown][admin_status: up][oper_status: up] [name: Gi1/1/4][description: GigabitEthernet1/1/4][alias: Uplink-Core][index: 36][port_security: disabled][status: securedown][violation_action: shutdown][admin_status: up][oper_status: up]
            ...      3     --include-interface='^Gi1/0/2$' --disco-show        <?xml version="1.0" encoding="utf-8"?> <data> <label admin_status="up" alias="Access-A" description="GigabitEthernet1/0/2" index="10" name="Gi1/0/2" oper_status="up" port_security="enabled" status="secureup" violation_action="dropNotify"/> </data>
            ...      4     --disco-format                                      <?xml version="1.0" encoding="utf-8"?> <data> <element>name</element> <element>description</element> <element>alias</element> <element>index</element> <element>port_security</element> <element>status</element> <element>violation_action</element> <element>admin_status</element> <element>oper_status</element> </data>
