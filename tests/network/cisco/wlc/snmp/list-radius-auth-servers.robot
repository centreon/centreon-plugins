*** Settings ***
Documentation       

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::wlc::snmp::plugin


*** Test Cases ***
list-radius-auth-servers ${tc}
    [Tags]    network    wlc    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-radius-auth-servers
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/wlc/snmp/slim_cisco_wlc
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --verbose                                                             List radius authentication servers: [name: 192.168.42.138:1812] [status: enable] [name: 192.168.42.169:1812] [status: enable] [name: 192.168.42.200:1645] [status: enable] [name: 192.168.42.20:1645] [status: enable] [name: 192.168.42.33:1812] [status: enable] [name: 192.168.42.82:1645] [status: enable]