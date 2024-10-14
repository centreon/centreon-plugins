*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vmware8-restapi.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::esx::plugin
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --mode=host-status
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000

*** Test Cases ***
Host-Status ${tc}
    [Tags]    apps    api    vmware   vsphere8    esx
    ${command}    Catenate    ${CMD} --http-backend=${http_backend} --esx-name=${esx_name} ${extraoptions}
    
    # We sort the host names and keep only the last one and make sure it is the expected one
    ${output}    Run    ${command}

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True
    
    
    Examples:    tc    http_backend     esx_name         extraoptions    expected_result   --
        ...      1     curl             esx1.acme.com    ${EMPTY}        OK: Host 'esx1.acme.com': power state is POWERED_ON, connection state is CONNECTED
        ...      2     lwp              esx1.acme.com    ${EMPTY}        OK: Host 'esx1.acme.com': power state is POWERED_ON, connection state is CONNECTED
        ...      3     curl             esx2.acme.com    ${EMPTY}        CRITICAL: Host 'esx2.acme.com': power state is POWERED_OFF
        ...      4     lwp              esx2.acme.com    ${EMPTY}        CRITICAL: Host 'esx2.acme.com': power state is POWERED_OFF
        ...      5     curl             esx3.acme.com    ${EMPTY}        CRITICAL: Host 'esx3.acme.com': connection state is DISCONNECTED
        ...      6     lwp              esx3.acme.com    ${EMPTY}        CRITICAL: Host 'esx3.acme.com': connection state is DISCONNECTED
        ...      7     curl             esx              ${EMPTY}        CRITICAL: Host 'esx2.acme.com': power state is POWERED_OFF - Host 'esx3.acme.com': connection state is DISCONNECTED
        ...      8     lwp              esx              ${EMPTY}        CRITICAL: Host 'esx2.acme.com': power state is POWERED_OFF - Host 'esx3.acme.com': connection state is DISCONNECTED
        ...      9     curl             nothing          ${EMPTY}        UNKNOWN: No ESX Host found.
        ...     10     lwp              nothing          ${EMPTY}        UNKNOWN: No ESX Host found.
        ...     11     curl             esx1.acme.com    --port=8888     UNKNOWN: curl perform error : Couldn't connect to server
        ...     12     lwp              esx1.acme.com    --port=8888     UNKNOWN: 500 Can't connect to 127.0.0.1:8888 (Connection refused)
