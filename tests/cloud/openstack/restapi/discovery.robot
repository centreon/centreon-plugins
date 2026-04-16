*** Settings ***
Documentation       OpenStack Discovery

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}openstack.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=cloud::openstack::restapi::plugin
...                 --mode=discovery
...                 --horizon-url=http://${HOSTNAME}:${APIPORT}
...                 --username=xxx
...                 --password=P@s$WoRdZ


*** Test Cases ***
Discovery ${tc}
    [Tags]    cloud     openstack     api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:        tc       extraoptions                                                              expected_regexp    --
            ...      1        --identity-url=http://${HOSTNAME}:${APIPORT}/v3                           "discovered_items":1
            ...      2        --identity-url=http://${HOSTNAME}:${APIPORT}/fake_keystone                "discovered_items":0

