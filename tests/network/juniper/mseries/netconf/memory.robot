*** Settings ***
Documentation       Juniper Mseries Netconf Memory

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}memory.netconf"

*** Test Cases ***
Memory ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY}
            ...    OK: All memory usages are ok | 'fpc slot 0 buffer#memory.usage.percentage'=25.00%;;;0;100 'fpc slot 0 heap#memory.usage.percentage'=9.00%;;;0;100 'fpc slot 5 buffer#memory.usage.percentage'=0.00%;;;0;100 'fpc slot 5 heap#memory.usage.percentage'=16.00%;;;0;100 'route engine slot 0#memory.usage.percentage'=5.00%;;;0;100
            ...    2     --filter-name="fpc slot 0 buffer"
            ...    OK: Memory 'fpc slot 0 buffer' usage: 25.00 % | 'fpc slot 0 buffer#memory.usage.percentage'=25.00%;;;0;100
            ...    3     --warning-usage-prct=7
            ...    WARNING: Memory 'fpc slot 0 buffer' usage: 25.00 % - Memory 'fpc slot 0 heap' usage: 9.00 % - Memory 'fpc slot 5 heap' usage: 16.00 % | 'fpc slot 0 buffer#memory.usage.percentage'=25.00%;0:7;;0;100 'fpc slot 0 heap#memory.usage.percentage'=9.00%;0:7;;0;100 'fpc slot 5 buffer#memory.usage.percentage'=0.00%;0:7;;0;100 'fpc slot 5 heap#memory.usage.percentage'=16.00%;0:7;;0;100 'route engine slot 0#memory.usage.percentage'=5.00%;0:7;;0;100
            ...    4     --critical-usage-prct=10
            ...    CRITICAL: Memory 'fpc slot 0 buffer' usage: 25.00 % - Memory 'fpc slot 5 heap' usage: 16.00 % | 'fpc slot 0 buffer#memory.usage.percentage'=25.00%;;0:10;0;100 'fpc slot 0 heap#memory.usage.percentage'=9.00%;;0:10;0;100 'fpc slot 5 buffer#memory.usage.percentage'=0.00%;;0:10;0;100 'fpc slot 5 heap#memory.usage.percentage'=16.00%;;0:10;0;100 'route engine slot 0#memory.usage.percentage'=5.00%;;0:10;0;100
