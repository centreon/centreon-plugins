*** Settings ***
Documentation       Juniper Mseries Netconf Memory

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
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

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY}
            ...    OK: All memory usages are ok | 'fpc slot 0 buffer#memory.usage.percentage'=25.00%;;;0;100 'fpc slot 0 heap#memory.usage.percentage'=9.00%;;;0;100 'fpc slot 5 buffer#memory.usage.percentage'=0.00%;;;0;100 'fpc slot 5 heap#memory.usage.percentage'=16.00%;;;0;100 'route engine slot 0#memory.usage.percentage'=5.00%;;;0;100
