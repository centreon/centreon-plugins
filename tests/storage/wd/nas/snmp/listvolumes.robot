*** Settings ***
Documentation       Check WD (Western Digital) NAS in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                                              ${CENTREON_PLUGINS} --plugin=storage::wd::nas::snmp::plugin

*** Test Cases ***
listvolumes${tc}
    [Tags]    listvolumes    storage    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-volumes
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/wd/nas/snmp/nas-wd
    ...    ${extra_option}
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_option                                        expected_result    --
            ...       1   --snmp-tls-their-identity                           List volumes: [name: Volume_1] [type: ext4]
            ...       2   --snmp-tls-their-hostname                           List volumes: [name: Volume_1] [type: ext4]
            ...       3   --snmp-tls-trust-cert                               List volumes: [name: Volume_1] [type: ext4]