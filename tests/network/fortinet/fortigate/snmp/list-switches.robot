*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::fortinet::fortigate::snmp::plugin

*** Test Cases ***
list-switches ${tc}
    [Tags]    network    list-switches
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-switches
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/fortinet/fortigate/snmp/slim_fortigate-switches
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                            expected_result    --
            ...      1     ${EMPTY}                                                 List switches: [Name = Anonymized 188] [Serial = Anonymized 209] [IP = 10.255.1.2] [Version = Anonymized 103] [State = up] [Admin = authorized] [Name = Anonymized 152] [Serial = Anonymized 146] [IP = 10.255.1.3] [Version = Anonymized 056] [State = up] [Admin = authorized]
            ...      2     --filter-name='Anonymized 188'                           List switches: [Name = Anonymized 188] [Serial = Anonymized 209] [IP = 10.255.1.2] [Version = Anonymized 103] [State = up] [Admin = authorized]
            ...      3     --filter-status='up'                                     List switches: [Name = Anonymized 188] [Serial = Anonymized 209] [IP = 10.255.1.2] [Version = Anonymized 103] [State = up] [Admin = authorized] [Name = Anonymized 152] [Serial = Anonymized 146] [IP = 10.255.1.3] [Version = Anonymized 056] [State = up] [Admin = authorized]
            ...      4     --filter-admin='toto'                                    UNKNOWN: No switch found matching.
            ...      5     --filter-ip='10.255.1.3'                                 List switches: [Name = Anonymized 152] [Serial = Anonymized 146] [IP = 10.255.1.3] [Version = Anonymized 056] [State = up] [Admin = authorized]
