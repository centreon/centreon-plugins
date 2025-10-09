*** Settings ***
Documentation       Cato Networks API Mode Dicovery

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}cato-api.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::security::cato::networks::api::plugin
...                 --mode discovery
...                 --hostname=${HOSTNAME}
...                 --account-id=123
...                 --api-key=321
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
Discovery ${tc}
    [Tags]    network    securirt    api    graphql    cato
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Json    ${command}    ${expected_result}


    Examples:      tc    extraoptions                                        expected_result    --
          ...      1     ${EMPTY}                                            {"discovered_items":3,"duration":0,"end_time":1758794547,"results":[{"connected_since":"2025-09-03T20:00:00Z","connectivity_status":"Connected","description":"HQ in Paris - main datacenter","id":"1001","last_connected":"2025-09-04T08:15:00Z","name":"Site Paris","operational_status":"active","pop_name":"POP-Paris"},{"connected_since":"","connectivity_status":"Disconnected","description":"Sud !","id":"1002","last_connected":"2025-09-03T23:45:00Z","name":"Site Toulouse","operational_status":"disabled","pop_name":"POP-Toulouse"},{"connected_since":"2025-09-04T01:30:00Z","connectivity_status":"Degraded","description":"Ariege","id":"1003","last_connected":"2025-09-04T07:50:00Z","name":"Site Saint Girons","operational_status":"locked","pop_name":"POP-Ariege"}],"start_time":1758794547}
          ...      2     --filter-site-name='Site Paris'                     {"discovered_items":1,"duration":0,"end_time":1758794685,"results":[{"connected_since":"2025-09-03T20:00:00Z","connectivity_status":"Connected","description":"HQ in Paris - main datacenter","id":"1001","last_connected":"2025-09-04T08:15:00Z","name":"Site Paris","operational_status":"active","pop_name":"POP-Paris"}],"start_time":1758794685} 
          ...      3     --filter-site-id='1002'                             {"discovered_items":1,"duration":0,"end_time":1758794705,"results":[{"connected_since":"","connectivity_status":"","description":"","id":"1002","last_connected":"","name":"Site Toulouse","operational_status":"","pop_name":""}],"start_time":1758794705}
          ...      4     --connectivity-details=0                            {"discovered_items":3,"duration":0,"end_time":1758794726,"results":[{"connected_since":"","connectivity_status":"","description":"","id":"1001","last_connected":"","name":"Site Paris","operational_status":"","pop_name":""},{"connected_since":"","connectivity_status":"","description":"","id":"1002","last_connected":"","name":"Site Toulouse","operational_status":"","pop_name":""},{"connected_since":"","connectivity_status":"","description":"","id":"1003","last_connected":"","name":"Site Saint Girons","operational_status":"","pop_name":""}],"start_time":1758794726}
