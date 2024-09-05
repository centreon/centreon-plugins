*** Settings ***
Documentation       Check swap table

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
    ...    --snmp-community=os/linux/snmp/swap
    ...    --snmp-timeout=1
    ...    --no-swap=${no-swap}
    ...    --warning-usage=${warning-usage}
    ...    --warning-usage-free=${warning-usage-free}
    ...    --warning-usage-prct=${warning-usage-prct}
    ...    --critical-usage=${critical-usage}
    ...    --critical-usage-free=${critical-usage-free}
    ...    --critical-usage-prct=${critical-usage-prct}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    no-swap      warning-usage      warning-usage-free      warning-usage-prct      critical-usage      critical-usage-free      critical-usage-prct    expected_result    --
            ...      1     ${EMPTY}     ${EMPTY}           ${EMPTY}                '10'                    ${EMPTY}            ${EMPTY}                 '30'                   OK: Swap Total: 976.00 MB Used: 0.00 B (0.00%) Free: 976.00 MB (100.00%) | 'used'=0B;;;0;1023406080 'free'=1023406080B;;;0;1023406080 'used_prct'=0.00%;0:10;0:30;0;100 
            ...      2     ''           ${EMPTY}           ${EMPTY}                ${EMPTY}                ${EMPTY}            ${EMPTY}                 ${EMPTY}               OK: Swap Total: 976.00 MB Used: 0.00 B (0.00%) Free: 976.00 MB (100.00%) | 'used'=0B;;;0;1023406080 'free'=1023406080B;;;0;1023406080 'used_prct'=0.00%;;;0;100
            ...      3     ${EMPTY}     ${EMPTY}           '10'                    ${EMPTY}                ${EMPTY}            '30'                     ${EMPTY}               CRITICAL: Swap Total: 976.00 MB Used: 0.00 B (0.00%) Free: 976.00 MB (100.00%) | 'used'=0B;;;0;1023406080 'free'=1023406080B;0:10;0:30;0;1023406080 'used_prct'=0.00%;;;0;100
            ...      4     ${EMPTY}     '100'              ${EMPTY}                ${EMPTY}                '100'               ${EMPTY}                 ${EMPTY}               OK: Swap Total: 976.00 MB Used: 0.00 B (0.00%) Free: 976.00 MB (100.00%) | 'used'=0B;0:100;0:100;0;1023406080 'free'=1023406080B;;;0;1023406080 'used_prct'=0.00%;;;0;100
            ...      5     ${EMPTY}     ${EMPTY}           '100'                   ${EMPTY}                ${EMPTY}            ${EMPTY}                 ${EMPTY}               WARNING: Swap Total: 976.00 MB Used: 0.00 B (0.00%) Free: 976.00 MB (100.00%) | 'used'=0B;;;0;1023406080 'free'=1023406080B;0:100;;0;1023406080 'used_prct'=0.00%;;;0;100