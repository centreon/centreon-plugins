*** Settings ***
Documentation       Juniper Mseries Netconf CPU

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=cpu
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=cpu
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="${CURDIR}${/}data${/}cpu.netconf"

*** Test Cases ***
Cpu ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extraoptions    expected_result    --
            ...      1     ${EMPTY}        OK: All CPU usages are ok | 'fpc slot 0#cpu.utilization.1m.percentage'=15.00%;;;0;100 'fpc slot 0#cpu.utilization.5m.percentage'=15.00%;;;0;100 'fpc slot 0#cpu.utilization.15m.percentage'=15.00%;;;0;100 'fpc slot 5#cpu.utilization.1m.percentage'=1.00%;;;0;100 'fpc slot 5#cpu.utilization.5m.percentage'=1.00%;;;0;100 'fpc slot 5#cpu.utilization.15m.percentage'=1.00%;;;0;100 'route engine slot 0#cpu.utilization.1m.percentage'=4.00%;;;0;100 'route engine slot 0#cpu.utilization.5m.percentage'=4.00%;;;0;100 'route engine slot 0#cpu.utilization.15m.percentage'=4.00%;;;0;100
