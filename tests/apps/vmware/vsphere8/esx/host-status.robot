*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

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
    ${command}    Catenate    ${CMD} ${filter_host} ${extraoptions}
    ${command_curl}    Catenate    ${command} --http-backend=curl
    ${command_lwp}     Catenate    ${command} --http-backend=lwp  
    Ctn Run Command And Check Result As Strings    ${command_curl}    ${expected_result}
    Ctn Run Command And Check Result As Strings    ${command_lwp}     ${expected_result}
    
    
    Examples:    tc     filter_host                 extraoptions                        expected_result   --
        ...      1      --esx-name=esx1.acme.com    ${EMPTY}                            OK: Host 'esx1.acme.com', id: 'host-22': power state is POWERED_ON, connection state is CONNECTED
        ...      2      --esx-name=esx2.acme.com    ${EMPTY}                            CRITICAL: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF
        ...      3      --esx-name=esx3.acme.com    ${EMPTY}                            CRITICAL: Host 'esx3.acme.com', id: 'host-35': connection state is DISCONNECTED
        ...      4      --esx-id=host-35            --esx-name=esx3.acme.com            CRITICAL: Host 'esx3.acme.com', id: 'host-35': connection state is DISCONNECTED
        ...      5      --esx-name=nothing          ${EMPTY}                            UNKNOWN: No ESX Host found.
        ...      6      --esx-id=host-35            --esx-name=esx2.acme.com            UNKNOWN: No ESX Host found.
        ...      7      --esx-id=host-22            ${EMPTY}                            OK: Host 'esx1.acme.com', id: 'host-22': power state is POWERED_ON, connection state is CONNECTED
        ...      8      --esx-id=host-28            ${EMPTY}                            CRITICAL: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF
        ...      9      --esx-id=host-35            ${EMPTY}                            CRITICAL: Host 'esx3.acme.com', id: 'host-35': connection state is DISCONNECTED
        ...     10      --esx-id=nothing            ${EMPTY}                            UNKNOWN: No ESX Host found.
        ...     11      --esx-id=host-28            --critical-power-status=0           OK: Host 'esx2.acme.com', id: 'host-28': power state is POWERED_OFF, connection state is CONNECTED
        ...     12      --esx-id=host-35            --critical-connection-status=0      OK: Host 'esx3.acme.com', id: 'host-35': power state is POWERED_ON, connection state is DISCONNECTED
