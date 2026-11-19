*** Settings ***
Documentation     Prometheus Node Exporter plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}mockoon.json

${BASE_URL}        http://${HOSTNAME}:${APIPORT}
${CMD}             ${CENTREON_PLUGINS} --plugin=cloud::prometheus::exporters::nodeexporter::plugin --mode=interfaces --hostname=${HOSTNAME} --port=${APIPORT}


*** Test Cases ***
Interfaces ${tc}
    [Tags]    cloud    prometheus
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    CRITICAL: interface 'dif0' operational status: unknown [admin: up]
    ...    2
    ...    --critical-interface-status=0
    ...    OK: All interfaces are ok
    ...    3
    ...    --filter-name=eth0
    ...    OK: interface 'eth0' operational status: up [admin: up]
    ...    4
    ...    --filter-name=eth0 --warning-interface-status=1
    ...    WARNING: interface 'eth0' operational status: up [admin: up]
    ...    5
    ...    --filter-name=eth0 --critical-interface-status=1
    ...    CRITICAL: interface 'eth0' operational status: up [admin: up]
    ...    6
    ...    --filter-instance=127.0.0.1:9101 --filter-name=eth0
    ...    OK: interface 'eth0' operational status: up [admin: up]
    ...    7
    ...    --url-path=/legacy/api/v1
    ...    CRITICAL: interface 'eth2' operational status: down [admin: up]
    ...    8
    ...    --url-path=/legacy/api/v1 --filter-name=eth1
    ...    OK: interface 'eth1' operational status: down [admin: down]
    ...    9
    ...    --url-path=/legacy/api/v1 --filter-name=eth3
    ...    OK: interface 'eth3' operational status: up [admin: unknown]
    ...    10
    ...    --url-path=/legacy/api/v1 --filter-name=^lo$
    ...    OK: interface 'lo' operational status: unknown [admin: up]
