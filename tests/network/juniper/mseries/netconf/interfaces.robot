*** Settings ***
Documentation       Juniper Mseries Netconf Interfaces

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}interfaces.netconf"

*** Test Cases ***
Interface ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY}
            ...    CRITICAL: Interface 'ge-0/2/0' status : down (admin: up) - Interface 'ge-0/2/0.199' status : down (admin: up) - Interface 'ge-0/2/0.32767' status : down (admin: up) - Interface 'ge-0/2/7' status : down (admin: up) - Interface 'ge-0/2/8' status : down (admin: up) - Interface 'ge-0/2/9' status : down (admin: up) - Interface 'ge-0/3/0' status : down (admin: up) - Interface 'ge-0/3/0.0' status : down (admin: up) - Interface 'ge-0/3/1' status : down (admin: up) - Interface 'ge-0/3/1.2301' status : down (admin: up) - Interface 'ge-0/3/1.32767' status : down (admin: up) - Interface 'ge-0/3/1.4002' status : down (admin: up) - Interface 'ge-0/3/4' status : down (admin: up) - Interface 'ge-0/3/4.118' status : down (admin: up) - Interface 'ge-0/3/4.32767' status : down (admin: up) - Interface 'ge-0/3/5' status : down (admin: up) - Interface 'ge-0/3/5.32767' status : down (admin: up) - Interface 'ge-0/3/5.4002' status : down (admin: up) - Interface 'ge-0/3/6' status : down (admin: up) - Interface 'ge-0/3/7' status : down (admin: up) - Interface 'ge-0/3/8' status : down (admin: up) - Interface 'ge-0/3/9' status : down (admin: up) - Interface 'xe-2/0/3' status : down (admin: up) - Interface 'xe-2/0/3.16386' status : down (admin: up)
