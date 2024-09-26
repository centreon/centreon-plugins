*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::windows::snmp::plugin

*** Test Cases ***
list-interfaces ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                               expected_result    --
            ...      1     --add-extra-oid=''                                                          UNKNOWN: Can't get interfaces...
            ...      2     --add-extra-oid=''                                                          UNKNOWN: Can't get interfaces...
            ...      3     --add-mac-address=''                                                        UNKNOWN: Can't get interfaces...
            ...      4     --display-transform-src='eth'                                               UNKNOWN: Can't get interfaces...
            ...      5     --display-transform-dst='ens'                                               UNKNOWN: Can't get interfaces...
