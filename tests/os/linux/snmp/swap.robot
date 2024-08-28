*** Settings ***
Documentation       Check table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
swap ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=swap
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --verbose                       CRITICAL: No active swap 
            ...      2     --no-swap                       CRITICAL: No active swap
            ...      3     --warning-usage='2'             CRITICAL: No active swap
            ...      4     --warning-usage-free=''         CRITICAL: No active swap 
            ...      5     --warning-usage-prct=''         CRITICAL: No active swap
            ...      6     --critical-usage=''             CRITICAL: No active swap
            ...      4     --critical-usage-free=''        CRITICAL: No active swap
            ...      5     --critical-usage-prct=''        CRITICAL: No active swap 
