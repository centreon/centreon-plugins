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

*** Test Cases ***
Interface ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}interfaces.netconf"
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY}
            ...    CRITICAL: Interface 'ge-0/2/0' status : down (admin: up) - Interface 'ge-0/2/0.199' status : down (admin: up) - Interface 'ge-0/2/0.32767' status : down (admin: up) - Interface 'ge-0/2/7' status : down (admin: up) - Interface 'ge-0/2/8' status : down (admin: up) - Interface 'ge-0/2/9' status : down (admin: up) - Interface 'ge-0/3/0' status : down (admin: up) - Interface 'ge-0/3/0.0' status : down (admin: up) - Interface 'ge-0/3/1' status : down (admin: up) - Interface 'ge-0/3/1.2301' status : down (admin: up) - Interface 'ge-0/3/1.32767' status : down (admin: up) - Interface 'ge-0/3/1.4002' status : down (admin: up) - Interface 'ge-0/3/4' status : down (admin: up) - Interface 'ge-0/3/4.118' status : down (admin: up) - Interface 'ge-0/3/4.32767' status : down (admin: up) - Interface 'ge-0/3/5' status : down (admin: up) - Interface 'ge-0/3/5.32767' status : down (admin: up) - Interface 'ge-0/3/5.4002' status : down (admin: up) - Interface 'ge-0/3/6' status : down (admin: up) - Interface 'ge-0/3/7' status : down (admin: up) - Interface 'ge-0/3/8' status : down (admin: up) - Interface 'ge-0/3/9' status : down (admin: up) - Interface 'xe-2/0/3' status : down (admin: up) - Interface 'xe-2/0/3.16386' status : down (admin: up)
            ...    2     --add-status
            ...    CRITICAL: Interface 'ge-0/2/0' status : down (admin: up) - Interface 'ge-0/2/0.199' status : down (admin: up) - Interface 'ge-0/2/0.32767' status : down (admin: up) - Interface 'ge-0/2/7' status : down (admin: up) - Interface 'ge-0/2/8' status : down (admin: up) - Interface 'ge-0/2/9' status : down (admin: up) - Interface 'ge-0/3/0' status : down (admin: up) - Interface 'ge-0/3/0.0' status : down (admin: up) - Interface 'ge-0/3/1' status : down (admin: up) - Interface 'ge-0/3/1.2301' status : down (admin: up) - Interface 'ge-0/3/1.32767' status : down (admin: up) - Interface 'ge-0/3/1.4002' status : down (admin: up) - Interface 'ge-0/3/4' status : down (admin: up) - Interface 'ge-0/3/4.118' status : down (admin: up) - Interface 'ge-0/3/4.32767' status : down (admin: up) - Interface 'ge-0/3/5' status : down (admin: up) - Interface 'ge-0/3/5.32767' status : down (admin: up) - Interface 'ge-0/3/5.4002' status : down (admin: up) - Interface 'ge-0/3/6' status : down (admin: up) - Interface 'ge-0/3/7' status : down (admin: up) - Interface 'ge-0/3/8' status : down (admin: up) - Interface 'ge-0/3/9' status : down (admin: up) - Interface 'xe-2/0/3' status : down (admin: up) - Interface 'xe-2/0/3.16386' status : down (admin: up)
            ...    3     --add-traffic
            ...    OK: All interfaces are ok
            ...    4     --add-errors
            ...    OK: All interfaces are ok
            ...    5     --add-extra-errors
            ...    OK: All interfaces are ok
            ...    6     --warning-status='\\\%{opstatus} ne "up"' --critical-status=''
            ...    WARNING: Interface 'ge-0/2/0' status : down (admin: up) - Interface 'ge-0/2/0.199' status : down (admin: up) - Interface 'ge-0/2/0.32767' status : down (admin: up) - Interface 'ge-0/2/7' status : down (admin: up) - Interface 'ge-0/2/8' status : down (admin: up) - Interface 'ge-0/2/9' status : down (admin: up) - Interface 'ge-0/3/0' status : down (admin: up) - Interface 'ge-0/3/0.0' status : down (admin: up) - Interface 'ge-0/3/1' status : down (admin: up) - Interface 'ge-0/3/1.2301' status : down (admin: up) - Interface 'ge-0/3/1.32767' status : down (admin: up) - Interface 'ge-0/3/1.4002' status : down (admin: up) - Interface 'ge-0/3/2' status : down (admin: down) - Interface 'ge-0/3/2.2301' status : down (admin: down) - Interface 'ge-0/3/2.32767' status : down (admin: down) - Interface 'ge-0/3/2.4002' status : down (admin: down) - Interface 'ge-0/3/4' status : down (admin: up) - Interface 'ge-0/3/4.118' status : down (admin: up) - Interface 'ge-0/3/4.32767' status : down (admin: up) - Interface 'ge-0/3/5' status : down (admin: up) - Interface 'ge-0/3/5.32767' status : down (admin: up) - Interface 'ge-0/3/5.4002' status : down (admin: up) - Interface 'ge-0/3/6' status : down (admin: up) - Interface 'ge-0/3/7' status : down (admin: up) - Interface 'ge-0/3/8' status : down (admin: up) - Interface 'ge-0/3/9' status : down (admin: up) - Interface 'xe-2/0/3' status : down (admin: up) - Interface 'xe-2/0/3.16386' status : down (admin: up)
            ...    7     --critical-status='\\\%{opstatus} eq "down"'
            ...    CRITICAL: Interface 'ge-0/2/0' status : down (admin: up) - Interface 'ge-0/2/0.199' status : down (admin: up) - Interface 'ge-0/2/0.32767' status : down (admin: up) - Interface 'ge-0/2/7' status : down (admin: up) - Interface 'ge-0/2/8' status : down (admin: up) - Interface 'ge-0/2/9' status : down (admin: up) - Interface 'ge-0/3/0' status : down (admin: up) - Interface 'ge-0/3/0.0' status : down (admin: up) - Interface 'ge-0/3/1' status : down (admin: up) - Interface 'ge-0/3/1.2301' status : down (admin: up) - Interface 'ge-0/3/1.32767' status : down (admin: up) - Interface 'ge-0/3/1.4002' status : down (admin: up) - Interface 'ge-0/3/2' status : down (admin: down) - Interface 'ge-0/3/2.2301' status : down (admin: down) - Interface 'ge-0/3/2.32767' status : down (admin: down) - Interface 'ge-0/3/2.4002' status : down (admin: down) - Interface 'ge-0/3/4' status : down (admin: up) - Interface 'ge-0/3/4.118' status : down (admin: up) - Interface 'ge-0/3/4.32767' status : down (admin: up) - Interface 'ge-0/3/5' status : down (admin: up) - Interface 'ge-0/3/5.32767' status : down (admin: up) - Interface 'ge-0/3/5.4002' status : down (admin: up) - Interface 'ge-0/3/6' status : down (admin: up) - Interface 'ge-0/3/7' status : down (admin: up) - Interface 'ge-0/3/8' status : down (admin: up) - Interface 'ge-0/3/9' status : down (admin: up) - Interface 'xe-2/0/3' status : down (admin: up) - Interface 'xe-2/0/3.16386' status : down (admin: up)
            ...    8     --filter-use=name --filter-interface=ge-0/2/0
            ...    CRITICAL: Interface 'ge-0/2/0' status : down (admin: up) - Interface 'ge-0/2/0.199' status : down (admin: up) - Interface 'ge-0/2/0.32767' status : down (admin: up)

Interface regex ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}interfaces.netconf"
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Regexp    ${tc}    ${command}    ${expected_result}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     ${EMPTY} --verbose
            ...    (checking interface '[a-zA-Z0-9\-\/\.]*'\\\\n\\\\s*status : (up|down) \\\\(admin: up\\\\)\\\\n){2,}
            ...    2     --add-status --verbose
            ...    (checking interface '[a-zA-Z0-9\-\/\.]*'\\\\n\\\\s*status : (up|down) \\\\(admin: up\\\\)\\\\n){2,}
            ...    3     --add-traffic --verbose
            ...    (checking interface '[a-zA-Z0-9\-\/\.]*'\\\\n\\\\s*traffic in: .*, traffic out: .*\\\\n){2,}
            ...    4     --add-errors --verbose
            ...    (checking interface '[a-zA-Z0-9\-\/\.]*'\\\\n\\\\s*packets in discard: .*, error: .*\\\\n\\\\s*packets out error: .*\\\\n){2,}
            ...    5     --add-extra-errors --verbose
            ...    (checking interface '[a-zA-Z0-9\-\/\.]*'\\\\n\\\\s*packets in fcs error: .*, runts: .*, l3 incomplete: .*, fifo error: .*, l2 mismatch timeout: .*, drop: .*, resource error: .*\\\\n\\\\s*packets out drop: .*, carrier transition: .*, collision: .*, mtu error: .*, aged: .*, hs link crc error: .*, fifo error: .*, resource error: .*\\\\n){2,}

Optical Interface ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}interfaces_optical.netconf"
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     --add-optical
            ...    OK: All interfaces are ok | 'ge-0/2/2#interface.bias.current.milliampere'=28.034mA;;;; 'ge-0/2/2#interface.output.power.dbm'=-5.00dBm;-10.00:-2.01;-11.02:-1.00;0; 'ge-0/2/2#interface.module.temperature.celsius'=37.00C;;;; 'ge-0/2/3#interface.bias.current.milliampere'=26.322mA;;;; 'ge-0/2/3#interface.output.power.dbm'=-4.89dBm;-10.00:-2.01;-11.02:-1.00;0; 'ge-0/2/3#interface.module.temperature.celsius'=41.10C;;;; 'ge-0/2/4#interface.bias.current.milliampere'=23.540mA;;;; 'ge-0/2/4#interface.output.power.dbm'=-5.06dBm;-10.00:-2.00;-11.02:-1.00;0; 'ge-0/2/4#interface.module.temperature.celsius'=37.90C;;;; 'ge-0/2/5#interface.bias.current.milliampere'=28.416mA;;;; 'ge-0/2/5#interface.output.power.dbm'=-5.78dBm;-9.03:-3.00;-10.00:-2.00;0; 'ge-0/2/5#interface.module.temperature.celsius'=39.20C;;;; 'ge-0/3/3#interface.bias.current.milliampere'=22.256mA;;;; 'ge-0/3/3#interface.output.power.dbm'=-11.37dBm;-16.02:-7.01;-16.99:-6.00;0; 'ge-0/3/3#interface.module.temperature.celsius'=35.60C;;;; 'xe-2/0/0#interface.bias.current.milliampere'=35.584mA;;;; 'xe-2/0/0#interface.output.power.dbm'=-2.78dBm;-8.01:0.50;-9.03:1.50;0; 'xe-2/0/0#interface.module.temperature.celsius'=44.10C;;;; 'xe-2/0/1#interface.bias.current.milliampere'=36.674mA;;;; 'xe-2/0/1#interface.output.power.dbm'=-3.96dBm;-8.01:0.50;-9.03:1.50;0; 'xe-2/0/1#interface.module.temperature.celsius'=43.80C;;;; 'xe-2/0/2#interface.bias.current.milliampere'=36.830mA;;;; 'xe-2/0/2#interface.output.power.dbm'=-2.41dBm;-7.52:2.50;-8.01:3.00;0; 'xe-2/0/2#interface.module.temperature.celsius'=36.00C;;;;
