*** Settings ***
Documentation       Forcepoint SD-WAN Mode Swap

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin


*** Test Cases ***
Swap ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=swap
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=40000
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint-swap
    ...    --no-swap=${no-swap}
    ...    --warning-usage=${warning-usage}
    ...    --warning-usage-free=${warning-usage-free}
    ...    --warning-usage-prct=${warning-usage-prct}
    ...    --critical-usage=${critical-usage}
    ...    --critical-usage-free=${critical-usage-free}
    ...    --critical-usage-prct=${critical-usage-prct}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    no-swap      warning-usage      warning-usage-free      warning-usage-prct      critical-usage      critical-usage-free      critical-usage-prct    expected_result    --
            ...      1     ${EMPTY}     ${EMPTY}           ${EMPTY}                '10'                    ${EMPTY}            ${EMPTY}                 '30'                   OK: Swap Total: 960.00 MB Used: 90.75 MB (9.45%) Free: 869.25 MB (90.55%) | 'used'=95158272B;;;0;1006628864 'free'=911470592B;;;0;1006628864 'used_prct'=9.45%;0:10;0:30;0;100
            ...      2     ''           ${EMPTY}           ${EMPTY}                ${EMPTY}                ${EMPTY}            ${EMPTY}                 ${EMPTY}               OK: Swap Total: 960.00 MB Used: 90.75 MB (9.45%) Free: 869.25 MB (90.55%) | 'used'=95158272B;;;0;1006628864 'free'=911470592B;;;0;1006628864 'used_prct'=9.45%;;;0;100
            ...      3     ${EMPTY}     ${EMPTY}           '10'                    ${EMPTY}                ${EMPTY}            '30'                     ${EMPTY}               CRITICAL: Swap Total: 960.00 MB Used: 90.75 MB (9.45%) Free: 869.25 MB (90.55%) | 'used'=95158272B;;;0;1006628864 'free'=911470592B;0:10;0:30;0;1006628864 'used_prct'=9.45%;;;0;100
            ...      4     ${EMPTY}     ':5'              ${EMPTY}                ${EMPTY}                '100:'               ${EMPTY}                 ${EMPTY}               WARNING: Swap Total: 960.00 MB Used: 90.75 MB (9.45%) Free: 869.25 MB (90.55%) | 'used'=95158272B;0:5;100:;0;1006628864 'free'=911470592B;;;0;1006628864 'used_prct'=9.45%;;;0;100
            ...      5     ${EMPTY}     ${EMPTY}           '100'                   ${EMPTY}                ${EMPTY}            ${EMPTY}                 ${EMPTY}               WARNING: Swap Total: 960.00 MB Used: 90.75 MB (9.45%) Free: 869.25 MB (90.55%) | 'used'=95158272B;;;0;1006628864 'free'=911470592B;0:100;;0;1006628864 'used_prct'=9.45%;;;0;100
