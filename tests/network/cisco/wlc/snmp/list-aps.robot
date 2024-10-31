*** Settings ***
Documentation       

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::wlc::snmp::plugin


*** Test Cases ***
list-aps ${tc}
    [Tags]    network    wlc    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-aps
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/wlc/snmp/slim_cisco_wlc
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --verbose                                                             List aps [oid_path: 0.58.153.219.235.176] [name: Anonymized 015] [location: Anonymized 087] [model: Anonymized 139] [oid_path: 0.58.153.220.6.240] [name: Anonymized 201] [location: Anonymized 185] [model: Anonymized 242] [oid_path: 0.58.153.247.79.224] [name: Anonymized 181] [location: Anonymized 091] [model: Anonymized 019] [oid_path: 0.58.153.247.87.224] [name: Anonymized 035] [location: Anonymized 108] [model: Anonymized 228] [oid_path: 0.58.154.214.76.160] [name: Anonymized 089] [location: Anonymized 125] [model: Anonymized 103] [oid_path: 0.58.154.90.217.144] [name: Anonymized 072] [location: Anonymized 061] [model: Anonymized 047] [oid_path: 0.58.154.90.247.144] [name: Anonymized 122] [location: Anonymized 016] [model: Anonymized 104] [oid_path: 0.58.154.90.247.16] [name: Anonymized 007] [location: Anonymized 070] [model: Anonymized 143] [oid_path: 120.114.93.105.224.128] [name: Anonymized 249] [location: Anonymized 187] [model: Anonymized 186] [oid_path: 120.114.93.120.249.176] [name: Anonymized 108] [location: Speckworld in Säule] [model: Anonymized 191]