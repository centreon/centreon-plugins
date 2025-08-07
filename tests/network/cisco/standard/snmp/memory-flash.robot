*** Settings ***
Documentation       Network citrix netscaler health
Suite Setup         Ctn Generic Suite Setup
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
memory-flash ${tc}
    [Tags]    network    memory-flash    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory-flash
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                                          expected_result    --
            ...      1     ${EMPTY}                                                                                               OK: All memory flash partitions are ok | 'Anonymized 175#memory.flash.usage.bytes'=68809216B;;;0;122185728 'Anonymized 175#memory.flash.free.bytes'=53376512B;;;0;122185728 'Anonymized 175#memory.flash.usage.percentage'=56.32%;;;0;100 'Anonymized 163#memory.flash.usage.bytes'=68844544B;;;0;122185728 'Anonymized 163#memory.flash.free.bytes'=53341184B;;;0;122185728 'Anonymized 163#memory.flash.usage.percentage'=56.34%;;;0;100 'Anonymized 131#memory.flash.usage.bytes'=65309184B;;;0;122185728 'Anonymized 131#memory.flash.free.bytes'=56876544B;;;0;122185728 'Anonymized 131#memory.flash.usage.percentage'=53.45%;;;0;100
            ...      2     --warning-status='\\\%{status} eq "readWrite"' --filter-name='Anonymized 175'                          WARNING: Partition 'Anonymized 175' status : readWrite | 'Anonymized 175#memory.flash.usage.bytes'=68809216B;;;0;122185728 'Anonymized 175#memory.flash.free.bytes'=53376512B;;;0;122185728 'Anonymized 175#memory.flash.usage.percentage'=56.32%;;;0;100
            ...      3     --critical-status='\\\%{status} eq "readWrite"' --filter-name='Anonymized 175'                         CRITICAL: Partition 'Anonymized 175' status : readWrite | 'Anonymized 175#memory.flash.usage.bytes'=68809216B;;;0;122185728 'Anonymized 175#memory.flash.free.bytes'=53376512B;;;0;122185728 'Anonymized 175#memory.flash.usage.percentage'=56.32%;;;0;100
            ...      4     --warning-usage='' --critical-usage='' --filter-name='Anonymized 175'                                  OK: Partition 'Anonymized 175' status : readWrite, Total: 116.53 MB Used: 65.62 MB (56.32%) Free: 50.90 MB (43.68%) | 'Anonymized 175#memory.flash.usage.bytes'=68809216B;;;0;122185728 'Anonymized 175#memory.flash.free.bytes'=53376512B;;;0;122185728 'Anonymized 175#memory.flash.usage.percentage'=56.32%;;;0;100
            ...      5     --warning-usage-free=50 --critical-usage-free='' --filter-name='Anonymized 175'                        WARNING: Partition 'Anonymized 175' Total: 116.53 MB Used: 65.62 MB (56.32%) Free: 50.90 MB (43.68%) | 'Anonymized 175#memory.flash.usage.bytes'=68809216B;;;0;122185728 'Anonymized 175#memory.flash.free.bytes'=53376512B;0:50;;0;122185728 'Anonymized 175#memory.flash.usage.percentage'=56.32%;;;0;100
            ...      6     --warning-usage-prct=0 --critical-usage-prct=1 --filter-name='Anonymized 175'                          CRITICAL: Partition 'Anonymized 175' Used : 56.32 % | 'Anonymized 175#memory.flash.usage.bytes'=68809216B;;;0;122185728 'Anonymized 175#memory.flash.free.bytes'=53376512B;;;0;122185728 'Anonymized 175#memory.flash.usage.percentage'=56.32%;0:0;0:1;0;100