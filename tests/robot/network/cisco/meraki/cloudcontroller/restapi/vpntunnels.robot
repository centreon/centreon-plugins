*** Settings ***
Documentation       Meraki VPN Tunnels

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}meraki.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=network::cisco::meraki::cloudcontroller::restapi::plugin 
...                 --api-token=EEECGFCGFCGF 
...                 --statefile-dir=/dev/shm/

*** Test Cases ***
Create cache from API
    [Tags]    meraki    api    vpn    network cache
    ${output}    Run
    ...    ${CMD} --mode=cache --proto http --port 3000 --hostname=127.0.0.1

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: Cache files created successfully
    ...    Wrong output result:\n\n ${output}\nInstead of:\n OK: Cache files created successfully\n\n
    # Mockoon is not needed any longer since the data are cached
    Stop Mockoon

Check if ${test_desc} works
    [Tags]    meraki    api    vpn    network
    ${output}    Run
    ...    ${CMD} --mode=vpn-tunnels --filter-network-name=${filter_network_name} --cache-use --critical-total-dormant=1:

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected}
    ...    Wrong output result:\n\n ${output}\nInstead of:\n ${expected}\n\n

    Examples:    test_desc        filter_network_name      expected   --
        ...      all links        .*                       OK: vpn tunnel 'C3PO-R2P2-BB88' status: dormant [mode: spoke] | 'vpn.tunnels.online.count'=0;;;0;1 'vpn.tunnels.offline.count'=0;;;0;1 'vpn.tunnels.dormant.count'=1;;1:;0;1
        ...      empty filter     ${EMPTY}                 OK: vpn tunnel 'C3PO-R2P2-BB88' status: dormant [mode: spoke] | 'vpn.tunnels.online.count'=0;;;0;1 'vpn.tunnels.offline.count'=0;;;0;1 'vpn.tunnels.dormant.count'=1;;1:;0;1
        ...      absurd filter    toto                     CRITICAL: Vpn tunnels dormant: 0 | 'vpn.tunnels.online.count'=0;;;0;0 'vpn.tunnels.offline.count'=0;;;0;0 'vpn.tunnels.dormant.count'=0;;1:;0;0

