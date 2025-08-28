*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vm::plugin
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --mode=discovery
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000

*** Test Cases ***
Discovery ${tc}
    [Tags]    apps    api    vmware   vsphere8    vm    discovery
    ${command}    Catenate    ${CMD} ${extra_options}
    
    Ctn Run Command And Check Result As Json    ${command}    ${expected_result}

    Examples:    tc    extra_options    expected_result    --
    ...          1     ${EMPTY}
    ...          {"discovered_items":3,"duration":0,"end_time":1756740577,"results":[{"family":"","guest_os":"","guest_os_full":"","ip_address":"","power_state":"POWERED_OFF","vm_name":"web-server-01","vmw_vm_id":"vm-7657"},{"family":"LINUX","guest_os":"DEBIAN_12_64","guest_os_full":"Debian GNU/Linux 12 (64-bit)","ip_address":"172.16.2.1","power_state":"POWERED_ON","vm_name":"db-server-01","vmw_vm_id":"vm-7722"},{"family":"WINDOWS","guest_os":"WINDOWS_SERVER_2021","guest_os_full":"Microsoft Windows Server 2022 (64-bit)","ip_address":"172.16.2.12","power_state":"POWERED_ON","vm_name":"web-server-02","vmw_vm_id":"vm-1234"}],"start_time":1756740577}
    ...          2     --filter-power-states=POWERED_ON
    ...          {"discovered_items":2,"duration":0,"end_time":1756740577,"results":[{"family":"LINUX","guest_os":"DEBIAN_12_64","guest_os_full":"Debian GNU/Linux 12 (64-bit)","ip_address":"172.16.2.1","power_state":"POWERED_ON","vm_name":"db-server-01","vmw_vm_id":"vm-7722"},{"family":"WINDOWS","guest_os":"WINDOWS_SERVER_2021","guest_os_full":"Microsoft Windows Server 2022 (64-bit)","ip_address":"172.16.2.12","power_state":"POWERED_ON","vm_name":"web-server-02","vmw_vm_id":"vm-1234"}],"start_time":1756740577}
    ...          3     --filter-power-states=POWERED_OFF
    ...          {"discovered_items":1,"duration":0,"end_time":1756740577,"results":[{"family":"","guest_os":"","guest_os_full":"","ip_address":"","power_state":"POWERED_OFF","vm_name":"web-server-01","vmw_vm_id":"vm-7657"}],"start_time":1756740577}
    ...          4     --filter-folders=My_Dir
    ...          {"discovered_items":1,"duration":0,"end_time":1756740577,"results":[{"family":"LINUX","guest_os":"DEBIAN_12_64","guest_os_full":"Debian GNU/Linux 12 (64-bit)","ip_address":"172.16.2.1","power_state":"POWERED_ON","vm_name":"db-server-01","vmw_vm_id":"vm-7722"}],"start_time":1756740577}

