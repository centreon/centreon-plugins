*** Settings ***
Documentation       Proxmox VE REST API Mode Discovery

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}proxmox.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=apps::proxmox::ve::restapi::plugin
...                 --mode discovery
...                 --hostname=${HOSTNAME}
...                 --api-username=xx
...                 --api-password=xx
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
Discovery ${tc}
    [Tags]    storage     api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:        tc       extraoptions                                          expected_regexp    --
            ...      1        ${EMPTY}                                              "discovered_items":3
            ...      2        --resource-type=vm                                    (?=.*"ip_addresses":\\\\["123.321.123.321","127.0.0.1"\\\\])(?=.*"os_info_name":"XxXxXx GNU/Linux")
            ...      3        --resource-type=node                                  ^(?!.*(ip_addresses|os_info_name)).*$
            ...      4        --resource-type=vm                                    "os_info_name":"XXXXX GNU/Linux"