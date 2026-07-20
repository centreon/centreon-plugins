*** Settings ***
Documentation       network::waystream::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::waystream::snmp::plugin
...         --mode=list-sfp-ports
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}


*** Test Cases ***
List-sfp-ports MS4000 ${tc}
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
    ...    List SFP [number: 1][serial: S1902216386][connector: lc][bitrate: 1300] [number: 10][serial: S1902216396][connector: lc][bitrate: 1300] [number: 11][serial: S1902216397][connector: lc][bitrate: 1300] [number: 12][serial: S1902216393][connector: lc][bitrate: 1300] [number: 13][serial: S1902216395][connector: lc][bitrate: 1300] [number: 14][serial: S1902216391][connector: lc][bitrate: 1300] [number: 15][serial: S1902216392][connector: lc][bitrate: 1300] [number: 16][serial: S1902216394][connector: lc][bitrate: 1300] [number: 17][serial: S1902217616][connector: lc][bitrate: 1300] [number: 18][serial: S1902217620][connector: lc][bitrate: 1300] [number: 19][serial: S1902217615][connector: lc][bitrate: 1300] [number: 2][serial: S1902216384][connector: lc][bitrate: 1300] [number: 20][serial: S1902217619][connector: lc][bitrate: 1300] [number: 21][serial: S1902217617][connector: lc][bitrate: 1300] [number: 22][serial: S1902217614][connector: lc][bitrate: 1300] [number: 23][serial: S1902217618][connector: lc][bitrate: 1300] [number: 24][serial: S2105160749][connector: lc][bitrate: 1300] [number: 25][serial: SOP850SN09760][connector: lc][bitrate: 10300] [number: 26][serial: ][connector: unknown][bitrate: 0] [number: 3][serial: S1902216383][connector: lc][bitrate: 1300] [number: 4][serial: S1902216385][connector: lc][bitrate: 1300] [number: 5][serial: S1902216382][connector: lc][bitrate: 1300] [number: 6][serial: S1902216400][connector: lc][bitrate: 1300] [number: 7][serial: S1902216399][connector: lc][bitrate: 1300] [number: 8][serial: S1902216381][connector: lc][bitrate: 1300] [number: 9][serial: S1902216398][connector: lc][bitrate: 1300]
    ...    2
    ...    --exclude-connector=lc
    ...    List SFP [number: 26][serial: ][connector: unknown][bitrate: 0]

List-sfp-ports MS7000 ${tc}
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
    ...    --include-connector=lc
    ...    List SFP [number: 49][serial: SOP850SN15169][connector: lc][bitrate: 10300]
    ...    2
    ...    --exclude-connector=c
    ...    List SFP [number: 33][serial: ][connector: unknown][bitrate: 0] [number: 34][serial: ][connector: unknown][bitrate: 0] [number: 35][serial: ][connector: unknown][bitrate: 0] [number: 36][serial: ][connector: unknown][bitrate: 0] [number: 37][serial: ][connector: unknown][bitrate: 0] [number: 38][serial: ][connector: unknown][bitrate: 0] [number: 39][serial: ][connector: unknown][bitrate: 0] [number: 40][serial: ][connector: unknown][bitrate: 0] [number: 41][serial: ][connector: unknown][bitrate: 0] [number: 42][serial: ][connector: unknown][bitrate: 0] [number: 43][serial: ][connector: unknown][bitrate: 0] [number: 44][serial: ][connector: unknown][bitrate: 0] [number: 45][serial: ][connector: unknown][bitrate: 0] [number: 46][serial: ][connector: unknown][bitrate: 0] [number: 47][serial: ][connector: unknown][bitrate: 0] [number: 48][serial: ][connector: unknown][bitrate: 0] [number: 50][serial: ][connector: unknown][bitrate: 0] [number: 51][serial: ][connector: unknown][bitrate: 0] [number: 52][serial: ][connector: unknown][bitrate: 0]
