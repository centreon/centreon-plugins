*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s
Test Setup          Ctn Cleanup Cache

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vmware8-restapi.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::esx::plugin
...                 --mode=host-status
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000

*** Test Cases ***
Host-Status ${tc}
    [Tags]    apps    api    vmware   vsphere8    esx
    ${command}    Catenate    ${CMD} --http-backend=${http_backend} ${filter_host} ${extraoptions}
    
    # We sort the host names and keep only the last one and make sure it is the expected one
    ${output}    Run    ${command}

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True
    
    
    Examples:    tc    http_backend     filter_host                    extraoptions    expected_result   --
        ...      1     curl             --esx-name=esx1.acme.com    ${EMPTY}        OK: Host 'esx1.acme.com', id: 'host-22': power state is POWERED_ON, connection state is CONNECTED
        ...      2     lwp              --esx-name=esx1.acme.com    ${EMPTY}        OK: Host 'esx1.acme.com', id: 'host-22': power state is POWERED_ON, connection state is CONNECTED
        ...      3     curl             --esx-name=esx2.acme.com    ${EMPTY}        CRITICAL: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF
        ...      4     lwp              --esx-name=esx2.acme.com    ${EMPTY}        CRITICAL: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF
        ...      5     curl             --esx-name=esx3.acme.com    ${EMPTY}        CRITICAL: Host 'esx3.acme.com', id: 'host-35': connection state is DISCONNECTED
        ...      6     lwp              --esx-name=esx3.acme.com    ${EMPTY}        CRITICAL: Host 'esx3.acme.com', id: 'host-35': connection state is DISCONNECTED
        ...      7     curl             --esx-name=esx              ${EMPTY}        CRITICAL: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF - Host 'esx3.acme.com', id: 'host-35': connection state is DISCONNECTED
        ...      8     lwp              --esx-name=esx              ${EMPTY}        CRITICAL: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF - Host 'esx3.acme.com', id: 'host-35': connection state is DISCONNECTED
        ...      9     curl             --esx-name=nothing          ${EMPTY}        UNKNOWN: No ESX Host found.
        ...     10     lwp              --esx-name=nothing          ${EMPTY}        UNKNOWN: No ESX Host found.
        ...     11     curl             --esx-name=esx1.acme.com    --port=8888     UNKNOWN: curl perform error : Couldn't connect to server
        ...     12     lwp              --esx-name=esx1.acme.com    --port=8888     UNKNOWN: 500 Can't connect to 127.0.0.1:8888 (Connection refused)
        ...     13     curl             --esx-id=host-22            ${EMPTY}        OK: Host 'esx1.acme.com', id: 'host-22': power state is POWERED_ON, connection state is CONNECTED
        ...     14     lwp              --esx-id=host-22            ${EMPTY}        OK: Host 'esx1.acme.com', id: 'host-22': power state is POWERED_ON, connection state is CONNECTED
        ...     15     curl             --esx-id=host-28            ${EMPTY}        CRITICAL: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF
        ...     16     lwp              --esx-id=host-28            ${EMPTY}        CRITICAL: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF
        ...     17     curl             --esx-id=host-35            ${EMPTY}        CRITICAL: Host 'esx3.acme.com', id: 'host-35': connection state is DISCONNECTED
        ...     18     lwp              --esx-id=host-35            ${EMPTY}        CRITICAL: Host 'esx3.acme.com', id: 'host-35': connection state is DISCONNECTED
        ...     19     curl             --esx-id=nothing            ${EMPTY}        UNKNOWN: No ESX Host found.
        ...     20     lwp              --esx-id=nothing            ${EMPTY}        UNKNOWN: No ESX Host found.
        ...     21     curl             --esx-id=host-28            --critical-power-status=0                                                                                   OK: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF, connection state is CONNECTED
        ...     22     lwp              --esx-id=host-28            --critical-power-status=0 --warning-power-status='\\\%{power_state} eq "POWERED_OFF"'                       WARNING: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF
        ...     23     curl             --esx-id=host-35            --critical-connection-status=0                                                                              OK: Host 'esx3.acme.com', id: 'host-35': power state is POWERED_ON, connection state is DISCONNECTED
        ...     24     lwp              --esx-id=host-35            --critical-connection-status=0 --warning-connection-status='\\\%{connection_state} eq "DISCONNECTED"'       WARNING: Host 'esx3.acme.com', id: 'host-35': connection state is DISCONNECTED
