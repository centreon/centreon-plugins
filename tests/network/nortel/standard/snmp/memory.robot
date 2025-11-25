*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::nortel::standard::snmp::plugin


*** Test Cases ***
memory-4950gts ${tc}
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/4950gts-pwr
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      extra_options                     expected_result    --
            ...      1       ${EMPTY}                          OK: Memory '3.10.0'

memory-5520-24t ${tc}
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/5520-24t
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      extra_options                     expected_result    --
            ...      1       ${EMPTY}                          OK: Memory 'slot_1' total: 1.94 GB used: 1.17 GB (60.39%) free: 785.41 MB (39.61%) | 'slot_1#memory.usage.bytes'=1255702528B;;;0;2079264768 'slot_1#memory.free.bytes'=823562240B;;;0;2079264768 'slot_1#memory.usage.percentage'=60.39%;;;0;100
            ...      2       --warning-usage-prct=0:0          WARNING: Memory 'slot_1' total: 1.94 GB used: 1.17 GB (60.39%) free: 785.41 MB (39.61%) | 'slot_1#memory.usage.bytes'=1255702528B;;;0;2079264768 'slot_1#memory.free.bytes'=823562240B;;;0;2079264768 'slot_1#memory.usage.percentage'=60.39%;0:0;;0;100
            ...      3       --critical-usage-prct=0:0         CRITICAL: Memory 'slot_1' total: 1.94 GB used: 1.17 GB (60.39%) free: 785.41 MB (39.61%) | 'slot_1#memory.usage.bytes'=1255702528B;;;0;2079264768 'slot_1#memory.free.bytes'=823562240B;;;0;2079264768 'slot_1#memory.usage.percentage'=60.39%;;0:0;0;100

memory-7520-48y-8c ${tc}
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/7520-48y-8c
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      extra_options                     expected_result    --
            ...      1       ${EMPTY}                          OK: Memory 'slot_1' total: 15.61 GB used: 2.10 GB (13.47%) free: 13.51 GB (86.53%) | 'slot_1#memory.usage.bytes'=2257336320B;;;0;16761507840 'slot_1#memory.free.bytes'=14504171520B;;;0;16761507840 'slot_1#memory.usage.percentage'=13.47%;;;0;100
            ...      2       --warning-usage-prct=0:0          WARNING: Memory 'slot_1' total: 15.61 GB used: 2.10 GB (13.47%) free: 13.51 GB (86.53%) | 'slot_1#memory.usage.bytes'=2257336320B;;;0;16761507840 'slot_1#memory.free.bytes'=14504171520B;;;0;16761507840 'slot_1#memory.usage.percentage'=13.47%;0:0;;0;100
            ...      3       --critical-usage-prct=0:0         CRITICAL: Memory 'slot_1' total: 15.61 GB used: 2.10 GB (13.47%) free: 13.51 GB (86.53%) | 'slot_1#memory.usage.bytes'=2257336320B;;;0;16761507840 'slot_1#memory.free.bytes'=14504171520B;;;0;16761507840 'slot_1#memory.usage.percentage'=13.47%;;0:0;0;100

memory-7520-48ye-8ce ${tc}
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/7520-48ye-8ce
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      extra_options                     expected_result    --
            ...      1       ${EMPTY}                          OK: Memory 'slot_1' total: 15.61 GB used: 2.12 GB (13.57%) free: 13.49 GB (86.43%) | 'slot_1#memory.usage.bytes'=2274920448B;;;0;16761507840 'slot_1#memory.free.bytes'=14486587392B;;;0;16761507840 'slot_1#memory.usage.percentage'=13.57%;;;0;100
            ...      2       --warning-usage-prct=0:0          WARNING: Memory 'slot_1' total: 15.61 GB used: 2.12 GB (13.57%) free: 13.49 GB (86.43%) | 'slot_1#memory.usage.bytes'=2274920448B;;;0;16761507840 'slot_1#memory.free.bytes'=14486587392B;;;0;16761507840 'slot_1#memory.usage.percentage'=13.57%;0:0;;0;100
            ...      3       --critical-usage-prct=0:0         CRITICAL: Memory 'slot_1' total: 15.61 GB used: 2.12 GB (13.57%) free: 13.49 GB (86.43%) | 'slot_1#memory.usage.bytes'=2274920448B;;;0;16761507840 'slot_1#memory.free.bytes'=14486587392B;;;0;16761507840 'slot_1#memory.usage.percentage'=13.57%;;0:0;0;100
