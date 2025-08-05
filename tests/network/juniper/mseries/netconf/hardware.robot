*** Settings ***
Documentation       Juniper Mseries Netconf Hardware

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}

*** Test Cases ***
Hardware ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}hardware.netconf"
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     --component=fan
            ...    OK: All 6 components are ok [6/6 fans]. | 'Top Rear Fan#hardware.fan.speed.rpm'=3930rpm;;;0; 'Bottom Rear Fan#hardware.fan.speed.rpm'=3810rpm;;;0; 'Top Middle Fan#hardware.fan.speed.rpm'=3810rpm;;;0; 'Bottom Middle Fan#hardware.fan.speed.rpm'=3780rpm;;;0; 'Top Front Fan#hardware.fan.speed.rpm'=3870rpm;;;0; 'Bottom Front Fan#hardware.fan.speed.rpm'=3870rpm;;;0; 'hardware.fan.count'=6;;;;
            ...    2     --component=pic
            ...    OK: All 3 components are ok [3/3 pic]. | 'hardware.pic.count'=3;;;;
            ...    3     --filter=temperature
            ...    OK: All 22 components are ok [1/1 afeb, 6/6 fans, 6/6 fpc, 2/2 mic, 3/3 pic, 4/4 psus]. | 'Top Rear Fan#hardware.fan.speed.rpm'=3930rpm;;;0; 'Bottom Rear Fan#hardware.fan.speed.rpm'=3810rpm;;;0; 'Top Middle Fan#hardware.fan.speed.rpm'=3810rpm;;;0; 'Bottom Middle Fan#hardware.fan.speed.rpm'=3780rpm;;;0; 'Top Front Fan#hardware.fan.speed.rpm'=3870rpm;;;0; 'Bottom Front Fan#hardware.fan.speed.rpm'=3870rpm;;;0; 'PEM 0#hardware.psu.dc.output.load.percentage'=13%;;;0;100 'PEM 1#hardware.psu.dc.output.load.percentage'=4%;;;0;100 'PEM 2#hardware.psu.dc.output.load.percentage'=11%;;;0;100 'PEM 3#hardware.psu.dc.output.load.percentage'=2%;;;0;100 'hardware.afeb.count'=1;;;; 'hardware.fan.count'=6;;;; 'hardware.fpc.count'=6;;;; 'hardware.mic.count'=2;;;; 'hardware.pic.count'=3;;;; 'hardware.psu.count'=4;;;;
            ...    4     --component=fan --warning='fan,.*,3850'
            ...    WARNING: Fan 'Top Rear Fan' speed is 3930 rpm - Fan 'Top Front Fan' speed is 3870 rpm - Fan 'Bottom Front Fan' speed is 3870 rpm | 'Top Rear Fan#hardware.fan.speed.rpm'=3930rpm;0:3850;;0; 'Bottom Rear Fan#hardware.fan.speed.rpm'=3810rpm;0:3850;;0; 'Top Middle Fan#hardware.fan.speed.rpm'=3810rpm;0:3850;;0; 'Bottom Middle Fan#hardware.fan.speed.rpm'=3780rpm;0:3850;;0; 'Top Front Fan#hardware.fan.speed.rpm'=3870rpm;0:3850;;0; 'Bottom Front Fan#hardware.fan.speed.rpm'=3870rpm;0:3850;;0; 'hardware.fan.count'=6;;;;
            ...    5     --component=fan --critical='fan,.*,3900'
            ...    CRITICAL: Fan 'Top Rear Fan' speed is 3930 rpm | 'Top Rear Fan#hardware.fan.speed.rpm'=3930rpm;;0:3900;0; 'Bottom Rear Fan#hardware.fan.speed.rpm'=3810rpm;;0:3900;0; 'Top Middle Fan#hardware.fan.speed.rpm'=3810rpm;;0:3900;0; 'Bottom Middle Fan#hardware.fan.speed.rpm'=3780rpm;;0:3900;0; 'Top Front Fan#hardware.fan.speed.rpm'=3870rpm;;0:3900;0; 'Bottom Front Fan#hardware.fan.speed.rpm'=3870rpm;;0:3900;0; 'hardware.fan.count'=6;;;;

Hardware no fan ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}hardware_no_fan.netconf"
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     --component=fan --no-component=unknown
            ...    UNKNOWN: No components are checked.

