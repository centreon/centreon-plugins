*** Settings ***
Documentation       Discover firewalls managed by Panorama.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon-paloalto-api.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::paloalto::api::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --mode=discovery


*** Test Cases ***
discovery ${tc}
    [Tags]    network    paloalto    api    system

    ${command}    Catenate
    ...    ${CMD}
    ...    --auth-type=api-key
    ...    --api-key=D@pAs$W@rD
    ...    ${extra_options}

    Ctn Run Command And Check Result As Json    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    {"discovered_items":3,"duration":0,"end_time":1779952768,"results":[{"Connected":"yes","HostName":"fw-nyc.example.com","IpAddress":"192.168.1.1","Model":"PA-850","Serial":"FW-NYC"},{"Connected":"yes","HostName":"fw-london.example.com","IpAddress":"192.168.1.2","Model":"PA-850","Serial":"FW-LONDON"},{"Connected":"yes","HostName":"fw-tokyo.example.com","IpAddress":"192.168.1.3","Model":"PA-VM","Serial":"FW-TOKYO"}],"start_time":1779952768}
    ...    2
    ...    --include-model=PA-VM
    ...    {"discovered_items":1,"duration":0,"end_time":1779952789,"results":[{"Connected":"yes","HostName":"fw-tokyo.example.com","IpAddress":"192.168.1.3","Model":"PA-VM","Serial":"FW-TOKYO"}],"start_time":1779952789}
    ...    3
    ...    --exclude-model=PA-VM
    ...    {"discovered_items":2,"duration":0,"end_time":1779952792,"results":[{"Connected":"yes","HostName":"fw-nyc.example.com","IpAddress":"192.168.1.1","Model":"PA-850","Serial":"FW-NYC"},{"Connected":"yes","HostName":"fw-london.example.com","IpAddress":"192.168.1.2","Model":"PA-850","Serial":"FW-LONDON"}],"start_time":1779952792}
    ...    4
    ...    --include-ip-address=192.168.1.2
    ...    {"discovered_items":1,"duration":0,"end_time":1779952818,"results":[{"Connected":"yes","HostName":"fw-london.example.com","IpAddress":"192.168.1.2","Model":"PA-850","Serial":"FW-LONDON"}],"start_time":1779952818}
    ...    5
    ...    --exclude-ip-address=192.168.1.2
    ...    {"discovered_items":2,"duration":0,"end_time":1779952822,"results":[{"Connected":"yes","HostName":"fw-nyc.example.com","IpAddress":"192.168.1.1","Model":"PA-850","Serial":"FW-NYC"},{"Connected":"yes","HostName":"fw-tokyo.example.com","IpAddress":"192.168.1.3","Model":"PA-VM","Serial":"FW-TOKYO"}],"start_time":1779952822}
