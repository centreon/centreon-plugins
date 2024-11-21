*** Settings ***
Documentation       Network Teldat SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                          ${CENTREON_PLUGINS} --plugin=network::teldat::snmp::plugin


*** Test Cases ***
Memory ${tc}
    [Tags]    network    teldat    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=127.0.0.1
    ...    --snmp-version=2c
    ...    --snmp-port=2024
    ...    --snmp-community=network/teldat/snmp/teldat
    ...    --warning-usage=${warningusage}
    ...    --critical-usage=${criticalusage}
    ...    --warning-usage-free=${warningusagefree}
    ...    --critical-usage-free=${criticalusagefree}
    ...    --warning-usage-prct=${warningusageprct}
    ...    --critical-usage-prct=${criticalusageprct}
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}


    Examples:         tc  warningusage  criticalusage  warningusagefree  criticalusagefree  warningusageprct  criticalusageprct    expected_result    --
            ...       1   ${EMPTY}      ${EMPTY}       ${EMPTY}          ${EMPTY}           ${EMPTY}           ${EMPTY}            OK: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100
            ...       2   100           ${EMPTY}       ${EMPTY}          ${EMPTY}           ${EMPTY}           ${EMPTY}            WARNING: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;0:100;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100
            ...       3   ${EMPTY}      100            ${EMPTY}          ${EMPTY}           ${EMPTY}           ${EMPTY}            CRITICAL: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;0:100;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100
            ...       4   ${EMPTY}      ${EMPTY}       100               ${EMPTY}           ${EMPTY}           ${EMPTY}            WARNING: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;0:100;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100
            ...       5   ${EMPTY}      ${EMPTY}       ${EMPTY}          100                ${EMPTY}           ${EMPTY}            CRITICAL: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;0:100;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100
            ...       6   ${EMPTY}      ${EMPTY}       ${EMPTY}          ${EMPTY}           30                 ${EMPTY}            WARNING: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;0:30;;0;100
            ...       7   ${EMPTY}      ${EMPTY}       ${EMPTY}          ${EMPTY}           ${EMPTY}           30                  CRITICAL: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;0:30;0;100                 
