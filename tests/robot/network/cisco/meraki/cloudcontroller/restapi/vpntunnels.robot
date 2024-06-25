*** Settings ***
Documentation       Meraki VPN Tunnels

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}meraki.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=network::cisco::meraki::cloudcontroller::restapi::plugin 
...                 --mode=vpn-tunnels 
...                 --api-token=EEECGFCGFCGF 
...                 --statefile-dir=/dev/shm/ 
...                 --hostname=127.0.0.1 
...                 --port 3000 
...                 --proto http
...                 --critical-total-dormant=1:


*** Test Cases ***
Check if ${test_desc} works
    [Tags]    meraki    api    vpn    network
    ${output}    Run
    ...    ${CMD} --filter-network-name=${filter_network_name}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected}
    ...    Wrong output result:\n\n ${output}\nInstead of:\n ${expected}\n\n

    Examples:    test_desc        filter_network_name      expected   --
        ...      all links        .*                       OK: vpn tunnel 'C3PO-R2P2-BB88' status: dormant [mode: spoke] | 'vpn.tunnels.online.count'=0;;;0;1 'vpn.tunnels.offline.count'=0;;;0;1 'vpn.tunnels.dormant.count'=1;;1:;0;1
        ...      empty filter     ${EMPTY}                 OK: vpn tunnel 'C3PO-R2P2-BB88' status: dormant [mode: spoke] | 'vpn.tunnels.online.count'=0;;;0;1 'vpn.tunnels.offline.count'=0;;;0;1 'vpn.tunnels.dormant.count'=1;;1:;0;1
        ...      absurd filter    toto                    CRITICAL: Vpn tunnels dormant: 0 | 'vpn.tunnels.online.count'=0;;;0;0 'vpn.tunnels.offline.count'=0;;;0;0 'vpn.tunnels.dormant.count'=0;;1:;0;0

