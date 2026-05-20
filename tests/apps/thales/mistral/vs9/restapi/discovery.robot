*** Settings ***
Documentation       apps::thales::mistral::vs9::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mistral-mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::thales::mistral::vs9::restapi::plugin
...                 --mode=discovery
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=1
...                 --api-password=1


*** Test Cases ***
Discovery ${tc}
    [Tags]    apps    thales    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Json    ${command}    ${expected_json}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_json
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    {"discovered_items":2,"duration":0,"end_time":1747232859,"results":[{"description":"","firmware_version_current":"9.2.4.12","firmware_version_other":"9.2.4.10","gateway_active":"yes","gateway_administration_ip":"10.10.100.20","gateway_blackIpRemote_address":"100.100.100.10","gateway_blackIpRemote_address_netmask":24,"gateway_name":"gw-adm-a-2","gateway_offline":"no","gateway_private_address":"100.100.100.10","gateway_private_address_netmask":24,"gateway_responder_only":"","id":471,"name":"gw-adm-a-2","physical_interfaces":[],"platform_model":"HW","product_name":"IP9001","serial_number":"DASERIAL"},{"description":"","firmware_version_current":"9.2.4.12","firmware_version_other":"9.2.4.10","gateway_active":"yes","gateway_administration_ip":"10.10.10.10","gateway_blackIpRemote_address":"100.100.100.10","gateway_blackIpRemote_address_netmask":24,"gateway_name":"gw-ano-1","gateway_offline":"no","gateway_private_address":"100.100.100.10","gateway_private_address_netmask":24,"gateway_responder_only":"","id":470,"name":"gw-adm-a-1","physical_interfaces":[],"platform_model":"HW","product_name":"IP9001","serial_number":"987654.000001"}],"start_time":1747232851}
    ...    2
    ...    --resource-type=device
    ...    {"discovered_items":2,"duration":0,"end_time":1747232859,"results":[{"description":"","firmware_version_current":"9.2.4.12","firmware_version_other":"9.2.4.10","gateway_active":"yes","gateway_administration_ip":"10.10.100.20","gateway_blackIpRemote_address":"100.100.100.10","gateway_blackIpRemote_address_netmask":24,"gateway_name":"gw-adm-a-2","gateway_offline":"no","gateway_private_address":"100.100.100.10","gateway_private_address_netmask":24,"gateway_responder_only":"","id":471,"name":"gw-adm-a-2","physical_interfaces":[],"platform_model":"HW","product_name":"IP9001","serial_number":"DASERIAL"},{"description":"","firmware_version_current":"9.2.4.12","firmware_version_other":"9.2.4.10","gateway_active":"yes","gateway_administration_ip":"10.10.10.10","gateway_blackIpRemote_address":"100.100.100.10","gateway_blackIpRemote_address_netmask":24,"gateway_name":"gw-ano-1","gateway_offline":"no","gateway_private_address":"100.100.100.10","gateway_private_address_netmask":24,"gateway_responder_only":"","id":470,"name":"gw-adm-a-1","physical_interfaces":[],"platform_model":"HW","product_name":"IP9001","serial_number":"987654.000001"}],"start_time":1747232851}
