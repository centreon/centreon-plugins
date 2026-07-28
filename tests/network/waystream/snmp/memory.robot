*** Settings ***
Documentation       network::waystream::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::waystream::snmp::plugin
...         --mode=memory
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}


*** Test Cases ***
Memory MS4000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms4000
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Ram Total: 2.00 GB Used: 77.59 MB (57.10%) Free: 879.97 MB (42.90%) | 'memory.usage.bytes'=81358848B;;;0;2147483648 'memory.free.bytes'=922714112B;;;0;2147483648 'memory.usage.percentage'=57.10%;;;0;100
    ...    2
    ...    --warning-usage=1
    ...    WARNING: Ram Total: 2.00 GB Used: 77.59 MB (57.10%) Free: 879.97 MB (42.90%) | 'memory.usage.bytes'=81358848B;;;0;2147483648 'memory.free.bytes'=922714112B;;;0;2147483648 'memory.usage.percentage'=57.10%;0:1;;0;100
    ...    3
    ...    --critical-usage=1
    ...    CRITICAL: Ram Total: 2.00 GB Used: 77.59 MB (57.10%) Free: 879.97 MB (42.90%) | 'memory.usage.bytes'=81358848B;;;0;2147483648 'memory.free.bytes'=922714112B;;;0;2147483648 'memory.usage.percentage'=57.10%;;0:1;0;100
    ...    4
    ...    --warning-usage-free=1
    ...    WARNING: Ram Total: 2.00 GB Used: 77.59 MB (57.10%) Free: 879.97 MB (42.90%) | 'memory.usage.bytes'=81358848B;;;0;2147483648 'memory.free.bytes'=922714112B;0:1;;0;2147483648 'memory.usage.percentage'=57.10%;;;0;100
    ...    5
    ...    --critical-usage-free=1
    ...    CRITICAL: Ram Total: 2.00 GB Used: 77.59 MB (57.10%) Free: 879.97 MB (42.90%) | 'memory.usage.bytes'=81358848B;;;0;2147483648 'memory.free.bytes'=922714112B;;0:1;0;2147483648 'memory.usage.percentage'=57.10%;;;0;100
    ...    6
    ...    --warning-usage-prct=1
    ...    WARNING: Ram Total: 2.00 GB Used: 77.59 MB (57.10%) Free: 879.97 MB (42.90%) | 'memory.usage.bytes'=81358848B;;;0;2147483648 'memory.free.bytes'=922714112B;;;0;2147483648 'memory.usage.percentage'=57.10%;0:1;;0;100
    ...    7
    ...    --critical-usage-prct=1
    ...    CRITICAL: Ram Total: 2.00 GB Used: 77.59 MB (57.10%) Free: 879.97 MB (42.90%) | 'memory.usage.bytes'=81358848B;;;0;2147483648 'memory.free.bytes'=922714112B;;;0;2147483648 'memory.usage.percentage'=57.10%;;0:1;0;100

Memory MS7000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms7000
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Ram Total: 1.00 GB Used: 145.59 MB (71.00%) Free: 297.27 MB (29.00%) | 'memory.usage.bytes'=152657920B;;;0;1073741824 'memory.free.bytes'=311709696B;;;0;1073741824 'memory.usage.percentage'=71.00%;;;0;100
    ...    2
    ...    --warning-usage=1
    ...    WARNING: Ram Total: 1.00 GB Used: 145.59 MB (71.00%) Free: 297.27 MB (29.00%) | 'memory.usage.bytes'=152657920B;;;0;1073741824 'memory.free.bytes'=311709696B;;;0;1073741824 'memory.usage.percentage'=71.00%;0:1;;0;100
    ...    3
    ...    --critical-usage=1
    ...    CRITICAL: Ram Total: 1.00 GB Used: 145.59 MB (71.00%) Free: 297.27 MB (29.00%) | 'memory.usage.bytes'=152657920B;;;0;1073741824 'memory.free.bytes'=311709696B;;;0;1073741824 'memory.usage.percentage'=71.00%;;0:1;0;100
    ...    4
    ...    --warning-usage-free=1
    ...    WARNING: Ram Total: 1.00 GB Used: 145.59 MB (71.00%) Free: 297.27 MB (29.00%) | 'memory.usage.bytes'=152657920B;;;0;1073741824 'memory.free.bytes'=311709696B;0:1;;0;1073741824 'memory.usage.percentage'=71.00%;;;0;100
    ...    5
    ...    --critical-usage-free=1
    ...    CRITICAL: Ram Total: 1.00 GB Used: 145.59 MB (71.00%) Free: 297.27 MB (29.00%) | 'memory.usage.bytes'=152657920B;;;0;1073741824 'memory.free.bytes'=311709696B;;0:1;0;1073741824 'memory.usage.percentage'=71.00%;;;0;100
    ...    6
    ...    --warning-usage-prct=1
    ...    WARNING: Ram Total: 1.00 GB Used: 145.59 MB (71.00%) Free: 297.27 MB (29.00%) | 'memory.usage.bytes'=152657920B;;;0;1073741824 'memory.free.bytes'=311709696B;;;0;1073741824 'memory.usage.percentage'=71.00%;0:1;;0;100
    ...    7
    ...    --critical-usage-prct=1
    ...    CRITICAL: Ram Total: 1.00 GB Used: 145.59 MB (71.00%) Free: 297.27 MB (29.00%) | 'memory.usage.bytes'=152657920B;;;0;1073741824 'memory.free.bytes'=311709696B;;;0;1073741824 'memory.usage.percentage'=71.00%;;0:1;0;100
