*** Settings ***
Documentation       Meraki VPN Tunnels

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}meraki.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=network::cisco::meraki::cloudcontroller::restapi::plugin
...                 --api-token=EEECGFCGFCGF


*** Test Cases ***
Create cache from API
    [Tags]    meraki    api    vpn    network cache
    ${output}    Run
    ...    ${CMD} --mode=cache --proto=http --port=${APIPORT} --hostname=${HOSTNAME}

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: Cache files created successfully
    ...    Wrong output result:\n\n ${output}\nInstead of:\n OK: Cache files created successfully\n\n
    # Mockoon is not needed any longer since the data are cached
    Stop Mockoon

vpn-tunnels ${tc}
    [Tags]    meraki    api    vpn    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=vpn-tunnels --cache-use ${extra_options}
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:    tc   extra_options                    expected_result   --
        ...      1    ${EMPTY}                         OK: device 'C3PO-R2P2-BB88' status: dormant [mode: spoke] - All VPNs are ok | 'vpn.tunnels.unreachable.count'=3;;;0;3
        ...      2    --warning-total-unreachable=0    WARNING: Number of VPNS unreachable: 3 | 'vpn.tunnels.unreachable.count'=3;0:0;;0;3
        ...      3    --critical-total-unreachable=0   CRITICAL: Number of VPNS unreachable: 3 | 'vpn.tunnels.unreachable.count'=3;;0:0;0;3
