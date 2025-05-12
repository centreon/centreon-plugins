*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}Mockoon.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=network::stormshield::api::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --api-username=username
...                 --api-password=password
...                 --proto=http
...                 --port=${APIPORT}
...                 --timeout=5


*** Test Cases ***
vpn-tunnels ${tc}
    [Tags]    network    api
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=vpn-tunnels
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                                                                                                        expected_result    --
            ...       1     ${EMPTY}                                                                                                            OK: Total VPN tunnels: 22 - All VPN tunnels are ok | 'vpn.tunnels.total.count'=22;;;0;
            ...       2     --filter-name='7ddb9fbb1faab23401c19beb20e31b62'                                                                    OK: Total VPN tunnels: 1 - VPN tunnel '7ddb9fbb1faab23401c19beb20e31b62' ike status: installed | 'vpn.tunnels.total.count'=1;;;0;
            ...       3     --filter-counters='tunnels-total'                                                                                   OK: Total VPN tunnels: 22 | 'vpn.tunnels.total.count'=22;;;0;
            ...       4     --unknown-status='\\\%{ikeStatus} =~ /installed/' --filter-name='3061933d03c01595f6a426cfb50c5e09'                  UNKNOWN: VPN tunnel '3061933d03c01595f6a426cfb50c5e09' ike status: installed | 'vpn.tunnels.total.count'=1;;;0;
            ...       5     --warning-status='\\\%{ikeStatus} =~ /installed/' --filter-name='2975a3940ace7eb1a13a006a51c66991'                  WARNING: VPN tunnel '2975a3940ace7eb1a13a006a51c66991' ike status: installed | 'vpn.tunnels.total.count'=1;;;0;
            ...       6     --critical-status='\\\%{ikeStatus} =~ /installed/' --filter-name='4793e3b444d2342a46df35dd0338f2cc'                 CRITICAL: VPN tunnel '4793e3b444d2342a46df35dd0338f2cc' ike status: installed | 'vpn.tunnels.total.count'=1;;;0;
            ...       7     --warning-tunnels-total=20 --critical-tunnels-total=25                                                              WARNING: Total VPN tunnels: 22 | 'vpn.tunnels.total.count'=22;0:20;0:25;0;
