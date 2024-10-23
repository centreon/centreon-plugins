*** Settings ***
Documentation       Check WD (Western Digital) NAS in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                                              ${CENTREON_PLUGINS} --plugin=storage::wd::nas::snmp::plugin

*** Test Cases ***
Volumes${tc}
    [Tags]    volumes    storage    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=volumes
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/wd/nas/snmp/nas-wd
    ...    ${extra_option}
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_option                                        expected_result    --
            ...       1   --filter-name                                       OK: volume 'Volume_1' space usage total: 7.20 TB used: 5.30 TB (73.61%) free: 1.90 TB (26.39%) | 'Volume_1#volume.space.usage.bytes'=5827411627212B;;;0;7916483719987.2 'Volume_1#volume.space.free.bytes'=2089072092774B;;;0;7916483719987.2 'Volume_1#volume.space.usage.percentage'=73.61%;;;0;100
            ...       2   --warning-space-usage-prct='50'                     WARNING: volume 'Volume_1' space usage total: 7.20 TB used: 5.30 TB (73.61%) free: 1.90 TB (26.39%) | 'Volume_1#volume.space.usage.bytes'=5827411627212B;;;0;7916483719987.2 'Volume_1#volume.space.free.bytes'=2089072092774B;;;0;7916483719987.2 'Volume_1#volume.space.usage.percentage'=73.61%;0:50;;0;100
            ...       3   --warning-space-usage='0'                           WARNING: volume 'Volume_1' space usage total: 7.20 TB used: 5.30 TB (73.61%) free: 1.90 TB (26.39%) | 'Volume_1#volume.space.usage.bytes'=5827411627212B;0:0;;0;7916483719987.2 'Volume_1#volume.space.free.bytes'=2089072092774B;;;0;7916483719987.2 'Volume_1#volume.space.usage.percentage'=73.61%;;;0;100
            ...       4   --warning-space-usage-free='0'                      WARNING: volume 'Volume_1' space usage total: 7.20 TB used: 5.30 TB (73.61%) free: 1.90 TB (26.39%) | 'Volume_1#volume.space.usage.bytes'=5827411627212B;;;0;7916483719987.2 'Volume_1#volume.space.free.bytes'=2089072092774B;0:0;;0;7916483719987.2 'Volume_1#volume.space.usage.percentage'=73.61%;;;0;100
            ...       5   --critical-space-usage-prct='50'                    CRITICAL: volume 'Volume_1' space usage total: 7.20 TB used: 5.30 TB (73.61%) free: 1.90 TB (26.39%) | 'Volume_1#volume.space.usage.bytes'=5827411627212B;;;0;7916483719987.2 'Volume_1#volume.space.free.bytes'=2089072092774B;;;0;7916483719987.2 'Volume_1#volume.space.usage.percentage'=73.61%;;0:50;0;100
            ...       6   --critical-space-usage='0'                          CRITICAL: volume 'Volume_1' space usage total: 7.20 TB used: 5.30 TB (73.61%) free: 1.90 TB (26.39%) | 'Volume_1#volume.space.usage.bytes'=5827411627212B;;0:0;0;7916483719987.2 'Volume_1#volume.space.free.bytes'=2089072092774B;;;0;7916483719987.2 'Volume_1#volume.space.usage.percentage'=73.61%;;;0;100
            ...       7   --critical-space-usage-free='0'                     CRITICAL: volume 'Volume_1' space usage total: 7.20 TB used: 5.30 TB (73.61%) free: 1.90 TB (26.39%) | 'Volume_1#volume.space.usage.bytes'=5827411627212B;;;0;7916483719987.2 'Volume_1#volume.space.free.bytes'=2089072092774B;;0:0;0;7916483719987.2 'Volume_1#volume.space.usage.percentage'=73.61%;;;0;100